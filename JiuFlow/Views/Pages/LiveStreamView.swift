import SwiftUI
import WebKit

struct LiveStreamView: View {
    @EnvironmentObject var apiService: APIService
    @State private var streams: [LiveEvent] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text(err)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if streams.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("配信予定はありません")
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(streams) { stream in
                            LiveEventCard(stream: stream)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color.jfDarkBg)
        .navigationTitle("SJJJF Live")
        .task {
            await loadEvents()
        }
    }

    private func loadEvents() async {
        isLoading = true
        errorMessage = nil
        guard let url = URL(string: "\(apiService.baseURL)/api/v1/live-events") else {
            errorMessage = "URLエラー"
            isLoading = false
            return
        }
        do {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            if let token = apiService.authToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            let (data, _) = try await URLSession.shared.data(for: request)
            // API returns {"events": [...]}
            struct LiveEventsResponse: Decodable {
                let events: [LiveEvent]
            }
            let decoded = try JSONDecoder().decode(LiveEventsResponse.self, from: data)
            streams = decoded.events
        } catch {
            streams = []
        }
        isLoading = false
    }
}

struct LiveEvent: Codable, Identifiable {
    let id: String
    let title: String
    let stream_url: String?
    let status: String
    let starts_at: String?
    let required_tier: String?

    var isLive: Bool { status == "live" }
    var isScheduled: Bool { status == "scheduled" }
    var isEnded: Bool { status == "ended" }
    var requiresBlackBelt: Bool { required_tier == "blackbelt" }

    var startsAtDate: Date? {
        guard let s = starts_at else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: s) { return d }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: s)
    }
}

struct LiveEventCard: View {
    let stream: LiveEvent
    @EnvironmentObject var premium: PremiumManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            statusRow
            titleRow
            contentArea
        }
        .padding()
        .background(Color.jfCardBg)
        .cornerRadius(16)
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            if stream.isLive {
                HStack(spacing: 4) {
                    Circle().fill(.red).frame(width: 8, height: 8)
                    Text("LIVE").font(.caption.bold()).foregroundColor(.red)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.red.opacity(0.15)).cornerRadius(6)
            } else if stream.isScheduled {
                Text("SCHEDULED")
                    .font(.caption2.bold()).padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2)).foregroundColor(.blue).cornerRadius(6)
            } else {
                Text("ENDED")
                    .font(.caption2.bold()).padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2)).foregroundColor(.gray).cornerRadius(6)
            }

            if stream.requiresBlackBelt {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill").font(.caption2)
                    Text("BLACK BELT").font(.caption2.bold())
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.jfGold.opacity(0.15)).foregroundColor(.jfGold).cornerRadius(6)
            }

            Spacer()
        }
    }

    private var titleRow: some View {
        Text(stream.title)
            .font(.headline)
            .foregroundColor(.white)
    }

    @ViewBuilder
    private var contentArea: some View {
        if stream.requiresBlackBelt && !premium.isPremium {
            PremiumGate(feature: "ライブ配信視聴") {
                playerOrInfo
            }
        } else {
            playerOrInfo
        }
    }

    @ViewBuilder
    private var playerOrInfo: some View {
        if stream.isLive, let urlStr = stream.stream_url, URL(string: urlStr) != nil {
            YouTubeWebView(urlString: urlStr)
                .frame(height: 200)
                .cornerRadius(10)
        } else if stream.isScheduled, let date = stream.startsAtDate {
            CountdownView(targetDate: date)
        } else if stream.isEnded {
            if let urlStr = stream.stream_url, URL(string: urlStr) != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Label("アーカイブ", systemImage: "archivebox.fill")
                        .font(.caption.bold()).foregroundColor(.gray)
                    YouTubeWebView(urlString: urlStr)
                        .frame(height: 200)
                        .cornerRadius(10)
                }
            } else {
                Label("配信終了", systemImage: "archivebox")
                    .font(.caption).foregroundColor(.gray)
            }
        }
    }
}

struct YouTubeWebView: UIViewRepresentable {
    let urlString: String

    /// Convert any YouTube watch/short URL to embed URL
    static func toEmbedURL(_ url: String) -> String {
        if url.contains("/embed/") { return url }
        if let range = url.range(of: "watch?v=") {
            let vid = String(url[range.upperBound...]).components(separatedBy: "&").first ?? ""
            if !vid.isEmpty { return "https://www.youtube.com/embed/\(vid)" }
        }
        if let range = url.range(of: "youtu.be/") {
            let vid = String(url[range.upperBound...]).components(separatedBy: "?").first ?? ""
            if !vid.isEmpty { return "https://www.youtube.com/embed/\(vid)" }
        }
        return url
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.scrollView.isScrollEnabled = false
        wv.backgroundColor = .black
        wv.isOpaque = false
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let embedURL = YouTubeWebView.toEmbedURL(urlString)
        guard let baseURL = URL(string: embedURL) else { return }
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <style>body{margin:0;background:#000;}iframe{width:100%;height:100%;}</style>
        </head>
        <body>
        <iframe src="\(embedURL)?autoplay=1&playsinline=1" frameborder="0"
          allow="autoplay; encrypted-media" allowfullscreen></iframe>
        </body>
        </html>
        """
        uiView.loadHTMLString(html, baseURL: baseURL)
    }
}

struct CountdownView: View {
    let targetDate: Date
    @State private var remaining: DateComponents = DateComponents()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 8) {
            Label("配信開始まで", systemImage: "clock.fill")
                .font(.caption).foregroundColor(.gray)
            HStack(spacing: 16) {
                countUnit(remaining.day ?? 0, "日")
                countUnit(remaining.hour ?? 0, "時間")
                countUnit(remaining.minute ?? 0, "分")
                countUnit(remaining.second ?? 0, "秒")
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
        .onAppear { updateRemaining() }
        .onReceive(timer) { _ in updateRemaining() }
    }

    private func countUnit(_ value: Int, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(max(0, value))")
                .font(.title2.bold().monospacedDigit())
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }

    private func updateRemaining() {
        remaining = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: Date(), to: targetDate)
    }
}
