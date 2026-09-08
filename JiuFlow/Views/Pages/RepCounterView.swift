import SwiftUI
import AudioToolbox

// MARK: - Rep / Technique Counter

struct RepCounterView: View {
    @EnvironmentObject var lang: LanguageManager

    @AppStorage("repcounter_technique") private var technique: String = ""
    @AppStorage("repcounter_lr_mode") private var lrMode: Bool = false
    @AppStorage("repcounter_goal") private var goalText: String = ""

    @State private var total: Int = 0
    @State private var left: Int = 0
    @State private var right: Int = 0
    @State private var goalHit = false
    @State private var showResetConfirm = false

    private var goal: Int { Int(goalText) ?? 0 }
    private var currentTotal: Int { lrMode ? left + right : total }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(lang.t("技名（任意）", en: "Technique (optional)", pt: "Tecnica (opcional)"))
                            .font(.caption.bold()).foregroundStyle(Color.jfTextTertiary)
                        TextField(lang.t("例: 腕十字打ち込み", en: "e.g. armbar uchikomi", pt: "ex: armlock"), text: $technique)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(Color.jfCardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(Color.jfTextPrimary)
                    }

                    Toggle(isOn: $lrMode) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lang.t("左右別カウント", en: "Left / right count", pt: "Esquerda / direita"))
                                .font(.subheadline.bold()).foregroundStyle(Color.jfTextPrimary)
                            Text(lang.t("片方の腕・脚だけの技用", en: "For one-sided techniques", pt: "Tecnicas assimetricas"))
                                .font(.caption2).foregroundStyle(Color.jfTextTertiary)
                        }
                    }
                    .tint(Color.jfRed)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(lang.t("目標回数（任意）", en: "Target reps (optional)", pt: "Meta (opcional)"))
                            .font(.caption.bold()).foregroundStyle(Color.jfTextTertiary)
                        TextField(lang.t("例: 100", en: "e.g. 100", pt: "ex: 100"), text: $goalText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(Color.jfCardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(Color.jfTextPrimary)
                    }
                }
                .padding(14).glassCard()

                if goal > 0 {
                    ProgressView(value: min(1, Double(currentTotal) / Double(goal)))
                        .tint(Color.jfRed)
                }

                VStack(spacing: 4) {
                    Text(lang.t("合計", en: "Total", pt: "Total"))
                        .font(.caption.bold()).foregroundStyle(Color.jfTextTertiary)
                    Text("\(currentTotal)")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundStyle(Color.jfTextPrimary)
                    if lrMode {
                        HStack(spacing: 20) {
                            Text(lang.t("左", en: "L", pt: "Esq") + " \(left)")
                            Text(lang.t("右", en: "R", pt: "Dir") + " \(right)")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.jfTextSecondary)
                    }
                }

                if lrMode {
                    HStack(spacing: 14) {
                        tapButton(lang.t("左", en: "LEFT", pt: "ESQ"), count: left) { tap(.left) }
                        tapButton(lang.t("右", en: "RIGHT", pt: "DIR"), count: right) { tap(.right) }
                    }
                } else {
                    tapButton(lang.t("タップしてカウント", en: "TAP TO COUNT", pt: "TOQUE"), count: nil) { tap(.single) }
                        .frame(height: 260)
                }

                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Text(lang.t("カウントをリセット", en: "Reset count", pt: "Reiniciar"))
                        .font(.subheadline.bold())
                }
                .padding(.top, 8)
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle(lang.t("レップカウンター", en: "Rep Counter", pt: "Contador"))
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            lang.t("カウントをリセットしますか？", en: "Reset the count?", pt: "Reiniciar a contagem?"),
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button(lang.t("リセット", en: "Reset", pt: "Reiniciar"), role: .destructive) { resetAll() }
            Button(lang.t("キャンセル", en: "Cancel", pt: "Cancelar"), role: .cancel) {}
        }
    }

    private enum Side { case single, left, right }

    private func tapButton(_ label: String, count: Int?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(label).font(.headline).foregroundStyle(.white)
                if let count {
                    Text("\(count)")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LinearGradient.jfRedGradient)
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .frame(height: count == nil ? nil : 220)
        .sensoryFeedback(.impact(flexibility: .rigid), trigger: currentTotal)
    }

    private func tap(_ side: Side) {
        switch side {
        case .single: total += 1
        case .left: left += 1
        case .right: right += 1
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        checkGoal()
    }

    private func checkGoal() {
        guard goal > 0, currentTotal >= goal, !goalHit else { return }
        goalHit = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1025)
    }

    private func resetAll() {
        total = 0
        left = 0
        right = 0
        goalHit = false
    }
}

#Preview {
    NavigationStack {
        RepCounterView()
            .environmentObject(LanguageManager())
    }
}
