import SwiftUI

// MARK: - Training Tools Hub
// ラウンドタイマー・ドリルタイマー・レップカウンターへの入り口。
// Web版 jiuflow.com/tools と同じ3ツール構成。

struct ToolsHubView: View {
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                NavigationLink {
                    RollTimerView()
                } label: {
                    toolCard(
                        icon: "timer",
                        color: .orange,
                        title: lang.t("ラウンドタイマー", en: "Round Timer", pt: "Cronometro de Round"),
                        subtitle: lang.t("スパー用。ラウンド/休憩/本数を設定", en: "For sparring — set round, rest, and round count", pt: "Para sparring")
                    )
                }

                NavigationLink {
                    DrillTimerView()
                } label: {
                    toolCard(
                        icon: "figure.strengthtraining.functional",
                        color: .green,
                        title: lang.t("ドリルタイマー", en: "Drill Timer", pt: "Timer de Drill"),
                        subtitle: lang.t("タバタ/EMOM形式。打ち込み・ソロドリル用", en: "Tabata / EMOM presets for uchikomi & solo drilling", pt: "Tabata / EMOM")
                    )
                }

                NavigationLink {
                    RepCounterView()
                } label: {
                    toolCard(
                        icon: "number.circle.fill",
                        color: .jfRed,
                        title: lang.t("レップカウンター", en: "Rep Counter", pt: "Contador de Repeticoes"),
                        subtitle: lang.t("大きなタップボタン。左右別カウント・目標回数も設定可", en: "Big tap button, left/right split, optional goal", pt: "Toque grande")
                    )
                }
            }
            .padding(16)
        }
        .background(Color.jfDarkBg)
        .navigationTitle(lang.t("便利ツール", en: "Training Tools", pt: "Ferramentas"))
        .navigationBarTitleDisplayMode(.large)
    }

    private func toolCard(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.14))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.jfTextPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.jfTextTertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(Color.jfTextTertiary)
        }
        .padding(14)
        .glassCard()
        .hapticOnTap()
    }
}

#Preview {
    NavigationStack {
        ToolsHubView()
            .environmentObject(LanguageManager())
    }
}
