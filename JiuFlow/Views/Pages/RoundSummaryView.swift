import SwiftUI

// RollTimerView から呼ばれるラウンドサマリーポップアップ
// WearableManager.RoundSummary をそのまま表示する
struct RoundSummaryView: View {
    let summary: RoundSummary
    var onDismiss: (() -> Void)?

    var body: some View {
        ZStack {
            Color.jfDarkBg.ignoresSafeArea()
            VStack(spacing: 24) {
                // ヘッダー
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(scoreColor)
                    Text("ラウンド終了")
                        .font(.title2.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                }
                .padding(.top, 8)

                // スコア大表示
                VStack(spacing: 4) {
                    Text("\(summary.score)")
                        .font(.system(size: 80, weight: .black, design: .rounded))
                        .foregroundStyle(scoreColor)
                    Text(summary.label)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextSecondary)
                }

                // メトリクス
                HStack(spacing: 12) {
                    metricCard(icon: "clock.fill",   color: .orange,
                               title: "時間",        value: summary.durationString, unit: "")
                    metricCard(icon: "bolt.fill",    color: .yellow,
                               title: "スクランブル", value: "\(summary.scrambles)", unit: "回")
                    metricCard(icon: "waveform",     color: .purple,
                               title: "強度",        value: "\(summary.avg_intensity)", unit: "")
                }

                // 強度バー
                VStack(alignment: .leading, spacing: 6) {
                    Text("運動強度").font(.caption.bold()).foregroundStyle(Color.jfTextTertiary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.jfCardBg).frame(height: 10)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(intensityGradient)
                                .frame(width: geo.size.width * CGFloat(summary.avg_intensity) / 255.0, height: 10)
                                .animation(.easeOut(duration: 0.8), value: summary.avg_intensity)
                        }
                    }
                    .frame(height: 10)
                }
                .padding(12).glassCard()

                Button { onDismiss?() } label: {
                    Text("閉じる").font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(LinearGradient.jfRedGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
        }
    }

    private func metricCard(icon: String, color: Color, title: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color).font(.system(size: 14))
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.title3.bold().monospacedDigit()).foregroundStyle(Color.jfTextPrimary)
                if !unit.isEmpty {
                    Text(unit).font(.caption2).foregroundStyle(Color.jfTextTertiary)
                }
            }
            Text(title).font(.caption2).foregroundStyle(Color.jfTextTertiary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12).glassCard()
    }

    private var scoreColor: Color {
        switch summary.score {
        case 0..<30:  return .green
        case 30..<50: return .blue
        case 50..<70: return .orange
        default:      return Color.jfRed
        }
    }

    private var intensityGradient: LinearGradient {
        LinearGradient(colors: [.green, .yellow, .orange, .red], startPoint: .leading, endPoint: .trailing)
    }
}

// MARK: - ウェアラブルステータスバー (RollTimerView 内で使用)
struct WearableStatusBar: View {
    @ObservedObject var wearable: WearableManager

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(wearable.isConnected ? Color.green : Color.jfTextTertiary)
                .frame(width: 7, height: 7)
            Text(wearable.isConnected ? "ウェアラブル接続中" : "未接続")
                .font(.caption2)
                .foregroundStyle(wearable.isConnected ? Color.jfTextSecondary : Color.jfTextTertiary)
            Spacer()
            if let live = wearable.live, wearable.isConnected {
                intensityDots(live.intensity)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Color.jfCardBg.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func intensityDots(_ intensity: UInt8) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(intensity > UInt8(i * 50) ? dotColor(i) : Color.jfCardBg)
                    .frame(width: 5, height: 9 + CGFloat(i) * 2)
            }
        }
    }

    private func dotColor(_ level: Int) -> Color {
        switch level {
        case 0, 1: return .green
        case 2:    return .yellow
        case 3:    return .orange
        default:   return .red
        }
    }
}
