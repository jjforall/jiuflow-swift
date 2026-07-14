import SwiftUI
import AudioToolbox

// MARK: - Drill Interval Timer (Tabata / EMOM / Uchikomi)

struct DrillTimerView: View {
    @EnvironmentObject var lang: LanguageManager

    @State private var workDuration: Int = 30
    @State private var restDuration: Int = 30
    @State private var totalRounds: Int = 8

    @State private var currentRound: Int = 1
    @State private var timeRemaining: Int = 30
    @State private var isRunning = false
    @State private var isResting = false
    @State private var isFinished = false
    @State private var countdown: Int? = nil // 3-2-1 pre-start overlay
    @State private var timer: Timer?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                if isFinished {
                    finishedView
                } else if isRunning || timeRemaining != workDuration || currentRound != 1 {
                    activeView
                } else {
                    setupView
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle(lang.t("ドリルタイマー", en: "Drill Timer", pt: "Timer de Drill"))
        .navigationBarTitleDisplayMode(.large)
        .onDisappear { stopTimer() }
        .onChange(of: isRunning) { _, running in
            UIApplication.shared.isIdleTimerDisabled = running
        }
        .overlay {
            if let countdown {
                countdownOverlay(countdown)
            }
        }
    }

    // MARK: - Setup

    private var setupView: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text(lang.t("プリセット", en: "Presets", pt: "Predefinicoes"))
                    .font(.headline).foregroundStyle(Color.jfTextPrimary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    presetButton(lang.t("タバタ", en: "Tabata", pt: "Tabata"), "20s / 10s x 8", work: 20, rest: 10, rounds: 8)
                    presetButton("EMOM", lang.t("1分ごと x 10", en: "1min x 10", pt: "1min x 10"), work: 60, rest: 0, rounds: 10)
                    presetButton(lang.t("打ち込み", en: "Uchikomi", pt: "Uchikomi"), "30s / 15s x 10", work: 30, rest: 15, rounds: 10)
                    presetButton(lang.t("ロング", en: "Long", pt: "Longo"), "2min / 30s x 5", work: 120, rest: 30, rounds: 5)
                }
            }
            .padding(12).glassCard()

            VStack(alignment: .leading, spacing: 14) {
                stepperRow(lang.t("ワーク(秒)", en: "Work (sec)", pt: "Trabalho (s)"), value: $workDuration, range: 5...600, step: 5, color: .green)
                stepperRow(lang.t("レスト(秒)", en: "Rest (sec)", pt: "Descanso (s)"), value: $restDuration, range: 0...300, step: 5, color: .blue)
                stepperRow(lang.t("ラウンド数", en: "Rounds", pt: "Rounds"), value: $totalRounds, range: 1...30, step: 1, color: .jfTextSecondary)
            }
            .padding(12).glassCard()

            Button {
                startWithCountdown()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text(lang.t("スタート", en: "Start", pt: "Iniciar"))
                }
                .font(.headline).foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(LinearGradient.jfRedGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .sensoryFeedback(.impact(flexibility: .rigid), trigger: isRunning)
        }
    }

    private func presetButton(_ title: String, _ subtitle: String, work: Int, rest: Int, rounds: Int) -> some View {
        Button {
            workDuration = work
            restDuration = rest
            totalRounds = rounds
            timeRemaining = work
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold()).foregroundStyle(Color.jfTextPrimary)
                Text(subtitle).font(.caption2).foregroundStyle(Color.jfTextTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(
                (workDuration == work && restDuration == rest && totalRounds == rounds)
                    ? Color.jfRed.opacity(0.16) : Color.jfCardBg
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func stepperRow(_ label: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int, color: Color) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Color.jfTextSecondary)
            Spacer()
            Text("\(value.wrappedValue)")
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(Color.jfTextPrimary)
            Stepper("", value: value, in: range, step: step)
                .labelsHidden()
        }
    }

    // MARK: - Countdown overlay

    private func countdownOverlay(_ n: Int) -> some View {
        ZStack {
            Color.jfDarkBg.opacity(0.96).ignoresSafeArea()
            VStack(spacing: 8) {
                Text(lang.t("まもなくスタート", en: "Get Ready", pt: "Prepare-se"))
                    .font(.caption.bold()).foregroundStyle(Color.jfTextTertiary)
                Text("\(n)")
                    .font(.system(size: 96, weight: .black, design: .rounded))
                    .foregroundStyle(Color.jfRed)
            }
        }
    }

    // MARK: - Active view

    private var activeView: some View {
        VStack(spacing: 32) {
            Text(lang.t("ラウンド", en: "Round", pt: "Round") + " \(currentRound) / \(totalRounds)")
                .font(.title3.bold())
                .foregroundStyle(Color.jfTextPrimary)
                .padding(.top, 20)

            ZStack {
                Circle().stroke(Color.jfCardBg, lineWidth: 8).frame(width: 260, height: 260)
                let total = isResting ? max(restDuration, 1) : workDuration
                let progress = Double(timeRemaining) / Double(total)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(stateColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 260, height: 260)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeRemaining)

                VStack(spacing: 4) {
                    Text("\(timeRemaining)")
                        .font(.system(size: 72, weight: .bold, design: .monospaced))
                        .foregroundStyle(stateColor)
                    Text(isResting ? lang.t("レスト", en: "Rest", pt: "Descanso") : lang.t("ワーク", en: "Work", pt: "Trabalho"))
                        .font(.caption.bold())
                        .foregroundStyle(Color.jfTextTertiary)
                }
            }

            HStack(spacing: 24) {
                Button { resetTimer() } label: {
                    ZStack {
                        Circle().fill(Color.jfCardBg).frame(width: 60, height: 60)
                        Image(systemName: "arrow.counterclockwise").font(.title3.bold()).foregroundStyle(Color.jfTextSecondary)
                    }
                }
                Button {
                    if isRunning { pauseTimer() } else { resumeTimer() }
                } label: {
                    ZStack {
                        Circle().fill(LinearGradient.jfRedGradient).frame(width: 80, height: 80)
                        Image(systemName: isRunning ? "pause.fill" : "play.fill").font(.title.bold()).foregroundStyle(.white)
                    }
                }
                .sensoryFeedback(.impact(flexibility: .soft), trigger: isRunning)
            }
        }
    }

    private var stateColor: Color {
        isResting ? .blue : .green
    }

    // MARK: - Finished

    private var finishedView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 60)
            Image(systemName: "checkmark.circle.fill").font(.system(size: 80)).foregroundStyle(.green)
            Text(lang.t("完了！", en: "Done!", pt: "Concluido!")).font(.title.bold()).foregroundStyle(Color.jfTextPrimary)
            Text("\(totalRounds) " + lang.t("ラウンド", en: "rounds", pt: "rounds"))
                .font(.title3).foregroundStyle(Color.jfTextTertiary)
            Button { resetTimer() } label: {
                Text(lang.t("もう一度", en: "Again", pt: "De novo")).font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(LinearGradient.jfRedGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.top, 20)
            Spacer(minLength: 60)
        }
    }

    // MARK: - Controls

    private func startWithCountdown() {
        countdown = 3
        AudioServicesPlaySystemSound(1103)
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            DispatchQueue.main.async {
                guard let c = countdown else { t.invalidate(); return }
                if c <= 1 {
                    t.invalidate()
                    countdown = nil
                    startTimer()
                } else {
                    countdown = c - 1
                    AudioServicesPlaySystemSound(1103)
                }
            }
        }
    }

    private func startTimer() {
        currentRound = 1
        timeRemaining = workDuration
        isResting = false
        isFinished = false
        isRunning = true
        AudioServicesPlaySystemSound(1005)
        scheduleTimer()
    }

    private func resumeTimer() {
        isRunning = true
        scheduleTimer()
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        stopTimer()
        countdown = nil
        currentRound = 1
        timeRemaining = workDuration
        isResting = false
        isFinished = false
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async { tick() }
        }
    }

    private func tick() {
        guard isRunning else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
            if timeRemaining == 3 && timeRemaining > 0 {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        } else {
            handlePhaseEnd()
        }
    }

    private func handlePhaseEnd() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        if isResting {
            isResting = false
            currentRound += 1
            timeRemaining = workDuration
            AudioServicesPlaySystemSound(1005)
        } else if currentRound < totalRounds {
            if restDuration > 0 {
                isResting = true
                timeRemaining = restDuration
                AudioServicesPlaySystemSound(1006)
            } else {
                currentRound += 1
                timeRemaining = workDuration
                AudioServicesPlaySystemSound(1005)
            }
        } else {
            isFinished = true
            stopTimer()
            AudioServicesPlaySystemSound(1007)
        }
    }
}

#Preview {
    NavigationStack {
        DrillTimerView()
            .environmentObject(LanguageManager())
    }
}
