import SwiftUI

struct LiveStreamView: View {
    @EnvironmentObject var apiService: APIService
    @State private var streams: [LiveStream] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if streams.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No live streams scheduled")
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(streams) { stream in
                            streamCard(stream)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color.jfDarkBg)
        .navigationTitle("SJJJF Live")
        .task {
            streams = (try? await apiService.getLiveStreams()) ?? []
            isLoading = false
        }
    }

    func streamCard(_ s: LiveStream) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if s.isLive {
                    HStack(spacing: 4) {
                        Circle().fill(.red).frame(width: 8, height: 8)
                        Text("LIVE").font(.caption.bold()).foregroundColor(.red)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(6)
                } else {
                    Text("SCHEDULED")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.gray)
                        .cornerRadius(6)
                }

                if s.isPPV {
                    Text("PPV \u{00a5}\(s.ppv_price_jpy ?? 3000)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.2))
                        .foregroundColor(.yellow)
                        .cornerRadius(6)
                } else {
                    Text("FREE")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                }

                Spacer()
            }

            Text(s.title)
                .font(.headline)
                .foregroundColor(.white)

            if let desc = s.description {
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            if let time = s.scheduled_at {
                Label(time, systemImage: "clock")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            if s.isLive, let url = s.stream_url, let streamURL = URL(string: url) {
                Link(destination: streamURL) {
                    Text("Watch Now")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.jfRed)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.jfCardBg)
        .cornerRadius(16)
    }
}
