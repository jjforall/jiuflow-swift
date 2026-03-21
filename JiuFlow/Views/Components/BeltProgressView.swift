import SwiftUI

/// Belt level based on total practice hours
/// White → Blue → Purple → Brown → Black
struct BeltProgressView: View {
    let totalHours: Int

    private var beltInfo: (name: String, color: Color, emoji: String, nextBelt: String, hoursNeeded: Int, progress: Double) {
        switch totalHours {
        case 0..<50:
            return ("白帯", .white, "🤍", "青帯", 50, Double(totalHours) / 50.0)
        case 50..<200:
            return ("青帯", .blue, "💙", "紫帯", 200, Double(totalHours - 50) / 150.0)
        case 200..<500:
            return ("紫帯", .purple, "💜", "茶帯", 500, Double(totalHours - 200) / 300.0)
        case 500..<1000:
            return ("茶帯", .brown, "🤎", "黒帯", 1000, Double(totalHours - 500) / 500.0)
        default:
            return ("黒帯", .red, "🖤", "—", 0, 1.0)
        }
    }

    var body: some View {
        let info = beltInfo

        VStack(spacing: 12) {
            HStack(spacing: 10) {
                // Belt emoji
                Text(info.emoji)
                    .font(.title)

                VStack(alignment: .leading, spacing: 4) {
                    Text(info.name)
                        .font(.headline.bold())
                        .foregroundStyle(Color.jfTextPrimary)

                    if info.hoursNeeded > 0 {
                        Text("\(info.nextBelt)まであと\(info.hoursNeeded - totalHours)時間")
                            .font(.caption)
                            .foregroundStyle(Color.jfTextTertiary)
                    } else {
                        Text("おめでとうございます！")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }

                Spacer()

                Text("\(totalHours)h")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(info.color)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.jfBorder)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [info.color.opacity(0.7), info.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(info.progress, 1.0), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .glassCard()
    }
}

/// Streak celebration overlay
struct StreakCelebration: View {
    let days: Int
    @Binding var isShowing: Bool

    var body: some View {
        if isShowing {
            ZStack {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture { isShowing = false }

                VStack(spacing: 20) {
                    Text("🔥")
                        .font(.system(size: 80))
                        .scaleEffect(isShowing ? 1.0 : 0.3)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isShowing)

                    Text("\(days)日連続！")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text(streakMessage)
                        .font(.subheadline)
                        .foregroundStyle(Color.jfTextSecondary)
                        .multilineTextAlignment(.center)

                    Button {
                        isShowing = false
                    } label: {
                        Text("続けよう！")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(LinearGradient.jfRedGradient)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 8)
                }
                .padding(32)
            }
            .transition(.opacity)
        }
    }

    private var streakMessage: String {
        switch days {
        case 1...3: return "良いスタート！\nこの調子で続けよう"
        case 4...7: return "素晴らしい！\n1週間が見えてきた"
        case 8...14: return "すごい集中力！\n習慣になってきた"
        case 15...30: return "圧倒的な継続力！\nもう止められない"
        case 31...100: return "レジェンド級の継続！\n確実に強くなっている"
        default: return "人類最強の継続力！\n歴史に名を残すレベル"
        }
    }
}

/// Mastery rating view (for after watching a video)
struct MasteryRatingView: View {
    let techniqueName: String
    @Binding var level: Int // 0-4: 未学習/見た/練習中/使える/マスター
    var onSave: (() -> Void)?

    private let levels = [
        (0, "未学習", "circle", Color.gray),
        (1, "見た", "eye.fill", Color.blue),
        (2, "練習中", "arrow.triangle.2.circlepath", Color.orange),
        (3, "使える", "checkmark.circle.fill", Color.green),
        (4, "マスター", "star.fill", Color.yellow),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(Color.jfRed)
                Text("習熟度を記録")
                    .font(.caption.bold())
                    .foregroundStyle(Color.jfTextPrimary)
            }

            HStack(spacing: 6) {
                ForEach(levels, id: \.0) { lvl in
                    Button {
                        level = lvl.0
                        onSave?()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: lvl.2)
                                .font(.body)
                                .foregroundStyle(level >= lvl.0 ? lvl.3 : Color.jfTextTertiary.opacity(0.3))
                            Text(lvl.1)
                                .font(.system(size: 8))
                                .foregroundStyle(level >= lvl.0 ? Color.jfTextPrimary : Color.jfTextTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(12)
        .glassCard()
    }
}
