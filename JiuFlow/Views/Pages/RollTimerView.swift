import SwiftUI
import AudioToolbox

// MARK: - Roll Timer View

struct RollTimerView: View {
    @State private var roundDuration: Int = 300 // seconds
    @State private var restDuration: Int = 60
    @State private var totalRounds: Int = 5
    @State private var currentRound: Int = 1
    @State private var timeRemaining: Int = 300
    @State private var isRunning = false
    @State private var isResting = false
    @State private var isFinished = false
    @State private var timer: Timer?

    private let roundOptions = [180, 240, 300, 360, 480, 600]
    private let restOptions = [30, 60, 120]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                if isFinished {
                    finishedView
                } else if isRunning || timeRemaining != roundDuration {
                    timerActiveView
                } else {
                    timerSetupView
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Color.jfDarkBg)
        .navigationTitle("ロールタイマー")
        .navigationBarTitleDisplayMode(.large)
        .onDisappear { stopTimer() }
    }

    // MARK: - Setup View

    private var timerSetupView: some View {
        VStack(spacing: 20) {
            // Round duration
            VStack(alignment: .leading, spacing: 10) {
                Text("ラウンド時間").font(.headline).foregroundStyle(Color.jfTextPrimary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(roundOptions, id: \.self) { secs in
                            Button {
                                roundDuration = secs
                                timeRemaining = secs
                            } label: {
                                Text("\(secs / 60)分")
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 16).padding(.vertical, 10)
                                    .background(roundDuration == secs ? Color.jfRed : Color.jfCardBg)
                                    .foregroundStyle(roundDuration == secs ? .white : Color.jfTextSecondary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(12).glassCard()

            // Rest duration
            VStack(alignment: .leading, spacing: 10) {
                Text("休憩時間").font(.headline).foregroundStyle(Color.jfTextPrimary)
                HStack(spacing: 8) {
                    ForEach(restOptions, id: \.self) { secs in
                        Button {
                            restDuration = secs
                        } label: {
                            Text(secs < 60 ? "\(secs)秒" : "\(secs / 60)分")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(restDuration == secs ? Color.orange : Color.jfCardBg)
                                .foregroundStyle(restDuration == secs ? .white : Color.jfTextSecondary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(12).glassCard()

            // Number of rounds
            VStack(alignment: .leading, spacing: 10) {
                Text("ラウンド数").font(.headline).foregroundStyle(Color.jfTextPrimary)
                HStack {
                    Text("\(totalRounds) ラウンド")
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(Color.jfTextPrimary)
                    Spacer()
                    Stepper("", value: $totalRounds, in: 1...10)
                        .labelsHidden()
                }
            }
            .padding(12).glassCard()

            // Total time summary
            VStack(spacing: 6) {
                Text("合計時間")
                    .font(.caption).foregroundStyle(Color.jfTextTertiary)
                let total = totalRounds * roundDuration + max(0, totalRounds - 1) * restDuration
                Text(formatTime(total))
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(Color.jfTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(12).glassCard()

            // Start button
            Button {
                startTimer()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text("スタート")
                }
                .font(.headline).foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(LinearGradient.jfRedGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .sensoryFeedback(.impact(flexibility: .rigid), trigger: isRunning)
        }
    }

    // MARK: - Active Timer View

    private var timerActiveView: some View {
        VStack(spacing: 32) {
            // Round indicator
            Text(isResting ? "休憩" : "ラウンド \(currentRound) / \(totalRounds)")
                .font(.title3.bold())
                .foregroundStyle(isResting ? .orange : Color.jfTextPrimary)
                .padding(.top, 20)

            // Round dots
            HStack(spacing: 8) {
                ForEach(1...totalRounds, id: \.self) { r in
                    Circle()
                        .fill(r < currentRound ? Color.green : r == currentRound && !isResting ? timerColor : Color.jfCardBg)
                        .frame(width: 10, height: 10)
                }
            }

            // Big countdown
            ZStack {
                Circle()
                    .stroke(Color.jfCardBg, lineWidth: 8)
                    .frame(width: 260, height: 260)

                let total = isResting ? restDuration : roundDuration
                let progress = total > 0 ? Double(timeRemaining) / Double(total) : 0
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(timerColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 260, height: 260)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeRemaining)

                VStack(spacing: 4) {
                    Text(formatTime(timeRemaining))
                        .font(.system(size: 64, weight: .bold, design: .monospaced))
                        .foregroundStyle(timerColor)
                    if !isResting {
                        Text(isRunning ? "ファイト!" : "一時停止")
                            .font(.caption.bold())
                            .foregroundStyle(Color.jfTextTertiary)
                    }
                }
            }

            // Controls
            HStack(spacing: 24) {
                // Reset
                Button {
                    resetTimer()
                } label: {
                    ZStack {
                        Circle().fill(Color.jfCardBg).frame(width: 60, height: 60)
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title3.bold())
                            .foregroundStyle(Color.jfTextSecondary)
                    }
                }

                // Play/Pause
                Button {
                    if isRunning { pauseTimer() } else { resumeTimer() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.jfRedGradient)
                            .frame(width: 80, height: 80)
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                    }
                }
                .sensoryFeedback(.impact(flexibility: .soft), trigger: isRunning)

                // Skip round
                Button {
                    skipToNext()
                } label: {
                    ZStack {
                        Circle().fill(Color.jfCardBg).frame(width: 60, height: 60)
                        Image(systemName: "forward.fill")
                            .font(.title3.bold())
                            .foregroundStyle(Color.jfTextSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Finished View

    private var finishedView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 60)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("トレーニング完了!")
                .font(.title.bold())
                .foregroundStyle(Color.jfTextPrimary)

            Text("\(totalRounds)ラウンド x \(roundDuration / 60)分")
                .font(.title3)
                .foregroundStyle(Color.jfTextTertiary)

            Button {
                resetTimer()
            } label: {
                Text("もう一度").font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(LinearGradient.jfRedGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.top, 20)

            Spacer(minLength: 60)
        }
    }

    // MARK: - Timer Color

    private var timerColor: Color {
        if isResting { return .red }
        if timeRemaining <= 30 { return .orange }
        return .green
    }

    // MARK: - Timer Controls

    private func startTimer() {
        currentRound = 1
        timeRemaining = roundDuration
        isResting = false
        isFinished = false
        isRunning = true
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
        currentRound = 1
        timeRemaining = roundDuration
        isResting = false
        isFinished = false
    }

    private func skipToNext() {
        timer?.invalidate()
        timer = nil
        handleRoundEnd()
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                tick()
            }
        }
    }

    private func tick() {
        guard isRunning else { return }

        if timeRemaining > 0 {
            timeRemaining -= 1
            // Haptic at 30s warning
            if timeRemaining == 30 && !isResting {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            // Haptic at 10s
            if timeRemaining == 10 {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        } else {
            handleRoundEnd()
        }
    }

    private func handleRoundEnd() {
        // Sound + haptic
        AudioServicesPlaySystemSound(1005)
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        if isResting {
            // Rest ended, start next round
            isResting = false
            currentRound += 1
            timeRemaining = roundDuration
            if !isRunning {
                isRunning = true
                scheduleTimer()
            }
        } else if currentRound < totalRounds {
            // Round ended, start rest
            isResting = true
            timeRemaining = restDuration
        } else {
            // All rounds done
            isFinished = true
            stopTimer()
            AudioServicesPlaySystemSound(1007)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
