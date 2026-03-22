import SwiftUI

/// SNSにシェアできるステータスカード
struct StatusShareView: View {
    @StateObject private var journalStore = JournalStore()
    @StateObject private var rollStore = RollStore()
    @AppStorage("roadmap_progress") private var progressData: Data = Data()
    @State private var shareImage: UIImage?

    private var progress: [String: String] {
        (try? JSONDecoder().decode([String: String].self, from: progressData)) ?? [:]
    }

    private var streak: Int {
        let cal = Calendar.current
        let days = Set(journalStore.entries.map { cal.startOfDay(for: $0.date) })
        var s = 0
        var d = cal.startOfDay(for: Date())
        while days.contains(d) { s += 1; d = cal.date(byAdding: .day, value: -1, to: d)! }
        return s
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Share card
                shareCard
                    .id("card")

                // Share button
                if let img = shareImage {
                    ShareLink(item: Image(uiImage: img), preview: SharePreview("JiuFlow ステータス", image: Image(uiImage: img))) {
                        Label("SNSにシェア", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.jfRedGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                } else {
                    Button {
                        renderCard()
                    } label: {
                        Label("シェア画像を生成", systemImage: "photo.badge.plus")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.jfRedGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle("ステータス")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { renderCard() }
    }

    // MARK: - Share Card

    private var shareCard: some View {
        let done = progress.values.filter { $0 == "done" }.count
        let totalRolls = rollStore.entries.count
        let totalW = rollStore.entries.reduce(0) { $0 + $1.wins }
        let totalL = rollStore.entries.reduce(0) { $0 + $1.losses }
        let totalPractice = journalStore.entries.count
        let totalHours = journalStore.entries.reduce(0) { $0 + $1.duration } / 60

        return VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("JiuFlow")
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfRed)
                    Text("My BJJ Status")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
                Spacer()
                Text("🥋")
                    .font(.system(size: 36))
            }

            // Stats grid
            HStack(spacing: 0) {
                statBox("\(streak)", "連続日", .orange)
                statBox("\(totalPractice)", "練習回数", .blue)
                statBox("\(totalHours)h", "合計時間", .green)
            }

            HStack(spacing: 0) {
                statBox("\(totalRolls)", "ロール数", .purple)
                statBox("\(totalW)-\(totalL)", "勝-負", .jfRed)
                statBox("\(done)/48", "習得テクニック", .cyan)
            }

            // Heatmap
            VStack(alignment: .leading, spacing: 4) {
                Text("直近28日の練習")
                    .font(.caption2.bold())
                    .foregroundStyle(Color(white: 0.6))
                let cal = Calendar.current
                let today = cal.startOfDay(for: Date())
                let days = Set(journalStore.entries.map { cal.startOfDay(for: $0.date) })
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 3) {
                    ForEach(0..<28, id: \.self) { i in
                        let day = cal.date(byAdding: .day, value: -(27 - i), to: today)!
                        RoundedRectangle(cornerRadius: 2)
                            .fill(days.contains(day) ? Color.green : Color(white: 0.15))
                            .frame(height: 14)
                    }
                }
            }

            // Footer
            HStack {
                Text("jiuflow.art")
                    .font(.caption2)
                    .foregroundStyle(Color(white: 0.4))
                Spacer()
                Text(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none))
                    .font(.caption2)
                    .foregroundStyle(Color(white: 0.4))
            }
        }
        .padding(20)
        .background(
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.jfRed.opacity(0.3), lineWidth: 1)
        )
    }

    private func statBox(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color(white: 0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Render

    @MainActor
    private func renderCard() {
        let renderer = ImageRenderer(content:
            shareCard
                .frame(width: 360)
                .padding(4)
                .background(Color.black)
        )
        renderer.scale = 3
        shareImage = renderer.uiImage
    }
}
