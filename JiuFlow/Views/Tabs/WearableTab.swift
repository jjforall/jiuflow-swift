import SwiftUI
import Charts

struct WearableTab: View {
    @StateObject private var wearable  = WearableManager()
    @StateObject private var training  = TrainingLoadManager()
    @State private var showRoundDetail: RoundSummary? = nil
    @State private var isManualRound = false
    @State private var manualStartTime: Date? = nil
    @State private var manualElapsed: Int = 0
    @State private var manualTimer: Timer? = nil
    @State private var showIntensityPicker = false
    @State private var appear = false
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                // ── 背景: 上から下へ深いグラデーション ──
                LinearGradient(
                    colors: [Color(hex: "#0d0d0d"), Color(hex: "#080808")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        if FeatureFlags.bleHardwareEnabled {
                            connectionBar
                                .springIn(appear, delay: 0.02)
                        }
                        scoreHero
                            .springIn(appear, delay: 0.08)
                        if wearable.isConnected {
                            liveIntensityBar
                                .springIn(appear, delay: 0.12)
                        }
                        startStopButton
                            .springIn(appear, delay: 0.14)
                        todayStats
                            .springIn(appear, delay: 0.18)
                        if !wearable.todayRounds.isEmpty {
                            roundHistory
                        }
                        formCard
                            .springIn(appear, delay: wearable.todayRounds.isEmpty ? 0.22 : min(0.22 + Double(wearable.todayRounds.count) * 0.02, 0.9))
                        weeklyChart
                            .springIn(appear, delay: wearable.todayRounds.isEmpty ? 0.28 : min(0.28 + Double(wearable.todayRounds.count) * 0.02, 0.96))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 48)
                }
                .onAppear {
                    guard !hasAppeared else { return }
                    hasAppeared = true
                    withAnimation { appear = true }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("トレーニング")
                        .font(.headline.bold())
                        .foregroundStyle(Color.jfTextPrimary)
                }
            }
        }
        .sheet(item: $showRoundDetail) { round in
            RoundDetailSheet(round: round)
                .presentationDetents([.large])
        }
        .onChange(of: wearable.latestRound) { _, round in
            if let round { training.record(score: round.score) }
        }
    }

    // MARK: - Connection bar

    private var connectionBar: some View {
        HStack(spacing: 8) {
            // 状態インジケーター
            ZStack {
                if wearable.isScanning {
                    Circle()
                        .stroke(Color.orange.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                        .scaleEffect(1.6)
                        .animation(.easeInOut(duration: 0.9).repeatForever(), value: wearable.isScanning)
                }
                Circle()
                    .fill(wearable.isConnected ? Color.green : (wearable.isScanning ? .orange : Color.white.opacity(0.2)))
                    .frame(width: 8, height: 8)
            }
            .frame(width: 20)

            Text(connectionLabel)
                .font(.caption.bold())
                .foregroundStyle(wearable.isConnected ? Color.jfTextSecondary : Color.white.opacity(0.3))

            Spacer()

            if wearable.isSparring {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                    Text("スパーリング中")
                }
                .font(.caption2.bold())
                .foregroundStyle(.purple)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color.purple.opacity(0.15))
                .clipShape(Capsule())
            } else if wearable.isConnected, let live = wearable.live {
                Text(wearable.positionLabel)
                    .font(.caption2.bold())
                    .foregroundStyle(positionColor(live.position))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(positionColor(live.position).opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.top, 4)
    }

    // MARK: - Score hero (メイン表示)

    private var scoreHero: some View {
        ZStack {
            // 背景カード
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                ZStack {
                    // 外リング (track)
                    Circle()
                        .stroke(Color.white.opacity(0.10), lineWidth: 20)
                        .frame(width: 210, height: 210)

                    // スコアリング
                    Circle()
                        .trim(from: 0, to: CGFloat(wearable.todayScore) / 100.0)
                        .stroke(
                            AngularGradient(
                                colors: scoreGradientColors(wearable.todayScore),
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 210, height: 210)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 1.2, dampingFraction: 0.8), value: wearable.todayScore)
                        .shadow(color: scoreColor(wearable.todayScore).opacity(0.6), radius: 10)

                    // 中央コンテンツ
                    if wearable.todayRounds.isEmpty && !wearable.isConnected {
                        emptyStateCenter
                    } else {
                        activeScoreCenter
                    }
                }

                Spacer(minLength: 20)

                // スコアの説明テキスト
                if !wearable.todayRounds.isEmpty {
                    Text("今日の最高スコア")
                        .font(.caption.bold())
                        .foregroundStyle(Color.white.opacity(0.3))
                        .padding(.bottom, 20)
                }
            }
        }
        .frame(height: 290)
    }

    private var emptyStateCenter: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.martial.arts")
                .font(.system(size: 72, weight: .thin))
                .foregroundStyle(
                    LinearGradient(colors: [Color.white.opacity(0.35), Color.white.opacity(0.12)],
                                   startPoint: .top, endPoint: .bottom))
            VStack(spacing: 5) {
                Text("デバイスを接続")
                    .font(.headline.bold())
                    .foregroundStyle(Color.white.opacity(0.5))
                Text("または「ラウンドを開始」で手動記録")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.22))
            }
        }
    }

    private var activeScoreCenter: some View {
        VStack(spacing: 2) {
            Text("\(wearable.todayScore)")
                .font(.system(size: 86, weight: .black, design: .rounded))
                .foregroundStyle(scoreColor(wearable.todayScore))
                .contentTransition(.numericText())
                .animation(.spring(response: 0.6), value: wearable.todayScore)
                .shadow(color: scoreColor(wearable.todayScore).opacity(0.5), radius: 16)

            if !wearable.todayRounds.isEmpty {
                Text(scoreLabel(wearable.todayScore))
                    .font(.callout.bold())
                    .foregroundStyle(scoreColor(wearable.todayScore).opacity(0.8))
            }
        }
    }

    // MARK: - Live intensity bar

    @ViewBuilder
    private var liveIntensityBar: some View {
        if let live = wearable.live {
            HStack(spacing: 12) {
                Text("LIVE")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.jfRed)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Color.jfRed.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 3))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.07)).frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(
                                colors: [.green, .yellow, .orange, Color.jfRed],
                                startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * wearable.intensityPercent, height: 6)
                            .animation(.linear(duration: 0.2), value: wearable.intensityPercent)
                    }
                }.frame(height: 6)

                Text("\(Int(wearable.intensityPercent * 100))%")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(Color.white.opacity(0.5))
                    .frame(width: 34, alignment: .trailing)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Start / Stop ボタン

    private var startStopButton: some View {
        VStack(spacing: 8) {
            Button {
                if isManualRound {
                    // 終了 → 強度ピッカーを出す
                    manualTimer?.invalidate()
                    manualTimer = nil
                    showIntensityPicker = true
                    isManualRound = false
                } else {
                    // 開始
                    manualStartTime = Date()
                    manualElapsed = 0
                    isManualRound = true
                    manualTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                        manualElapsed = Int(Date().timeIntervalSince(manualStartTime ?? Date()))
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isManualRound ? "stop.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                    if isManualRound {
                        Text(timerString(manualElapsed))
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                            .contentTransition(.numericText())
                    } else {
                        Text("ラウンドを開始")
                            .font(.system(size: 15, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    isManualRound
                        ? LinearGradient(colors: [Color(hex:"#cc2200"), Color(hex:"#991a00")],
                                         startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color(hex:"#2c2c30"), Color(hex:"#1e1e22")],
                                         startPoint: .leading, endPoint: .trailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isManualRound ? Color.jfRed.opacity(0.7) : Color.white.opacity(0.25),
                            lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: isManualRound ? Color.jfRed.opacity(0.4) : Color.white.opacity(0.06), radius: 12)
            }
            .hapticOnTap(.medium)
            .animation(.spring(response: 0.3), value: isManualRound)
        }
        .sheet(isPresented: $showIntensityPicker) {
            ManualRoundSheet(elapsed: manualElapsed) { round in
                wearable.todayRounds.insert(round, at: 0)
                wearable.latestRound = round
                training.record(score: round.score)
            }
            .presentationDetents([.height(380)])
        }
    }

    private func timerString(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }

    // MARK: - Today stats (FB D4: 数字を大きく)

    private var todayStats: some View {
        HStack(spacing: 10) {
            statCard(
                value: "\(wearable.todayRounds.count)",
                unit: "ラウンド",
                icon: "repeat.circle.fill",
                color: Color(hex: "#4488ff")
            )
            statCard(
                value: "\(wearable.todayTotalMinutes)",
                unit: "分",
                icon: "clock.fill",
                color: .orange
            )
            statCard(
                value: "\(wearable.todayRounds.map(\.scrambles).reduce(0, +))",
                unit: "スクランブル",
                icon: "bolt.fill",
                color: .yellow
            )
        }
    }

    private func statCard(value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 20, weight: .semibold))
                .shadow(color: color.opacity(0.4), radius: 4)
            Text(value)
                .font(.system(size: 34, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.jfTextPrimary)
            Text(unit)
                .font(.caption.bold())
                .foregroundStyle(Color.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Round history

    @ViewBuilder
    private var roundHistory: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今日のラウンド")
                .font(.subheadline.bold())
                .foregroundStyle(Color.white.opacity(0.5))
                .springIn(appear, delay: 0.20)

            ForEach(Array(wearable.todayRounds.enumerated()), id: \.element.id) { idx, round in
                Button { showRoundDetail = round } label: {
                    roundRow(round)
                }
                .springIn(appear, delay: min(0.22 + Double(idx) * 0.035, 0.85))
            }
        }
    }

    private func roundRow(_ round: RoundSummary) -> some View {
        HStack(spacing: 14) {
            // スコアバッジ
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(scoreColor(round.score).opacity(0.15))
                    .frame(width: 52, height: 52)
                VStack(spacing: 1) {
                    Text("\(round.score)")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(scoreColor(round.score))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(round.label)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.jfTextPrimary)
                HStack(spacing: 8) {
                    Label(round.durationString, systemImage: "clock")
                    Label("\(round.scrambles)回", systemImage: "bolt.fill")
                    Label(round.fatigueLabel, systemImage: round.fatigue_index < 20 ? "checkmark.circle.fill" : "flame.fill")
                        .foregroundStyle(fatigueColor(round.fatigue_index))
                }
                .font(.caption2)
                .foregroundStyle(Color.white.opacity(0.35))
            }

            Spacer()

            // 疲労インジケーター
            VStack(spacing: 2) {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.2))
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - CTL/ATL/TSB form card

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header — TSBを主役に
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("コンディション")
                        .font(.caption.bold())
                        .foregroundStyle(Color.white.opacity(0.35))
                    Text(training.formLabel)
                        .font(.title3.bold())
                        .foregroundStyle(tsbColor)
                }
                Spacer()
                // TSB trending indicator
                Image(systemName: training.tsb > 5 ? "arrow.up.right" : training.tsb < -5 ? "arrow.down.right" : "arrow.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tsbColor)
                    .padding(8)
                    .background(tsbColor.opacity(0.12))
                    .clipShape(Circle())
            }

            // Three metrics: CTL | TSB | ATL
            HStack(spacing: 0) {
                tsbMetric(
                    value: training.ctl, label: "CTL",
                    desc: "フィットネス", color: Color(hex: "#4488ff")
                )
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1, height: 44)
                tsbMetric(
                    value: training.tsb, label: "TSB",
                    desc: training.formLabel, color: tsbColor,
                    showSign: true
                )
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1, height: 44)
                tsbMetric(
                    value: training.atl, label: "ATL",
                    desc: "疲労", color: .orange
                )
            }

            // 14-day score + CTL/ATL trend chart
            if training.trend.contains(where: { $0.score > 0 }) {
                Chart {
                    ForEach(training.trend) { day in
                        BarMark(
                            x: .value("日", String(day.id.suffix(5))),
                            y: .value("スコア", day.score)
                        )
                        .foregroundStyle(Color.white.opacity(0.10))
                        .cornerRadius(2)
                        LineMark(
                            x: .value("日", String(day.id.suffix(5))),
                            y: .value("CTL", day.ctl)
                        )
                        .foregroundStyle(Color(hex: "#4488ff").opacity(0.9))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                        LineMark(
                            x: .value("日", String(day.id.suffix(5))),
                            y: .value("ATL", day.atl)
                        )
                        .foregroundStyle(Color.orange.opacity(0.9))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: 7)) { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.2))
                            .font(.caption2)
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 64)
            }

            // Chart legend
            HStack(spacing: 14) {
                HStack(spacing: 4) {
                    Circle().fill(Color(hex: "#4488ff")).frame(width: 7, height: 7)
                    Text("CTL フィットネス").font(.system(size: 10)).foregroundStyle(Color.white.opacity(0.35))
                }
                HStack(spacing: 4) {
                    Circle().fill(Color.orange).frame(width: 7, height: 7)
                    Text("ATL 疲労").font(.system(size: 10)).foregroundStyle(Color.white.opacity(0.35))
                }
                Spacer()
            }

            // Advice
            Text(training.advice)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(tsbColor.opacity(0.85))
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var tsbColor: Color {
        switch training.formColor {
        case .red:    return Color.jfRed
        case .orange: return .orange
        case .white:  return Color.white.opacity(0.6)
        case .blue:   return Color(hex: "#4488ff")
        case .green:  return .green
        }
    }

    private func tsbMetric(value: Double, label: String, desc: String,
                           color: Color, showSign: Bool = false) -> some View {
        VStack(spacing: 3) {
            Text(showSign
                 ? (value >= 0
                    ? String(format: "+%.1f", value)
                    : String(format: "%.1f", value))
                 : String(format: "%.1f", value)
            )
            .font(.system(size: showSign ? 28 : 20, weight: .black, design: .rounded).monospacedDigit())
            .foregroundStyle(color)
            .shadow(color: color.opacity(showSign ? 0.5 : 0), radius: 6)
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.25))
            Text(desc)
                .font(.caption2)
                .foregroundStyle(Color.white.opacity(0.35))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Weekly chart (FB D3: 空グラフ改善)

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今週")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.white.opacity(0.5))
                Spacer()
                Text("目標 60")
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.2))
            }

            if weeklyData.allSatisfy({ $0.score == 0 }) {
                // FB D3: データなし時は励ましメッセージ
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Text("今週まだ道場に行ってない")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.white.opacity(0.3))
                        Text("サボる言い訳は後で。まず1ラウンドやれ。")
                            .font(.caption)
                            .foregroundStyle(Color.white.opacity(0.18))
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .frame(height: 80)
            } else {
                Chart {
                    ForEach(weeklyData, id: \.day) { item in
                        BarMark(
                            x: .value("曜日", item.day),
                            y: .value("スコア", item.score)
                        )
                        .foregroundStyle(
                            item.isToday
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [Color.jfRed, Color.jfRed.opacity(0.7)],
                                    startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(Color.white.opacity(0.12))
                        )
                        .cornerRadius(5)
                    }
                    RuleMark(y: .value("目標", 60))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(Color.white.opacity(0.15))
                }
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.3))
                            .font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 50, 100]) { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.05))
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.2))
                            .font(.caption2)
                    }
                }
                .frame(height: 100)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Helpers

    private struct WeekDay { var day: String; var score: Int; var isToday: Bool }

    private var weeklyData: [WeekDay] {
        let days = ["月","火","水","木","金","土","日"]
        let cal  = Calendar.current
        let todayIdx = (cal.component(.weekday, from: Date()) + 5) % 7
        return days.enumerated().map { i, day in
            WeekDay(day: day, score: i == todayIdx ? wearable.todayScore : 0, isToday: i == todayIdx)
        }
    }

    private var connectionLabel: String {
        if wearable.isConnected { return "デバイス接続中" }
        if wearable.isScanning  { return "スキャン中..." }
        return "デバイス未接続"
    }

    private func positionColor(_ pos: UInt8) -> Color {
        // Legacy (0-3): 1=standing, 2=ground, 3=scramble
        // ML (0-5): 0-4=ground types, 5=scramble
        if let bjj = wearable.live?.bjjPosition {
            switch bjj {
            case 5:       return Color.jfRed          // Scramble
            case 3, 4:    return .orange               // Mount / BackControl (dominant)
            default:      return .green                // Guard / HalfGuard / SideControl
            }
        }
        switch pos {
        case 1: return .blue
        case 2: return .green
        case 3: return Color.jfRed
        default: return Color.white.opacity(0.3)
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 0..<30:  return .green
        case 30..<50: return Color(hex: "#4488ff")
        case 50..<70: return .orange
        default:      return Color.jfRed
        }
    }

    private func scoreLabel(_ score: Int) -> String {
        switch score {
        case 0..<30:  return "軽め"
        case 30..<50: return "普通"
        case 50..<70: return "ハード"
        case 70..<85: return "激しい"
        default:      return "限界突破"
        }
    }

    private func scoreGradientColors(_ score: Int) -> [Color] {
        let base = scoreColor(score)
        return [base.opacity(0.6), base, base.opacity(0.8)]
    }

    private func fatigueColor(_ index: Int) -> Color {
        switch index {
        case 0..<20:  return .green
        case 20..<45: return .yellow
        case 45..<70: return .orange
        default:      return Color.jfRed
        }
    }
}

// MARK: - Spring entrance modifier

private extension View {
    func springIn(_ appear: Bool, delay: Double) -> some View {
        self
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 26)
            .animation(
                .spring(response: 0.52, dampingFraction: 0.72).delay(delay),
                value: appear
            )
    }
}

// MARK: - Round Detail Sheet

private struct RoundDetailSheet: View {
    let round: RoundSummary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: "#080808").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // ── ヘッダー ──
                    VStack(spacing: 8) {
                        Text("\(round.score)")
                            .font(.system(size: 96, weight: .black, design: .rounded))
                            .foregroundStyle(scoreColor(round.score))
                            .shadow(color: scoreColor(round.score).opacity(0.4), radius: 20)
                        Text(round.label)
                            .font(.title3.bold())
                            .foregroundStyle(scoreColor(round.score).opacity(0.8))
                        Text(round.durationString + "  のラウンド")
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.3))
                    }
                    .padding(.top, 32)

                    // ── 4メトリクス ──
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        metricCard(
                            icon: "bolt.fill",         color: .yellow,
                            title: "スクランブル",      value: "\(round.scrambles)回")
                        metricCard(
                            icon: "waveform",           color: .blue,
                            title: "平均強度",          value: "\(round.avg_intensity)")
                        metricCard(
                            icon: "arrow.up.right",     color: .orange,
                            title: "ピーク強度",        value: "\(round.peak_intensity)")
                        metricCard(
                            icon: "flame.fill",         color: fatigueColor(round.fatigue_index),
                            title: "疲労指数",          value: "\(round.fatigue_index)%")
                    }

                    // ── 疲労バー ──
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("体力の消耗")
                                .font(.caption.bold())
                                .foregroundStyle(Color.white.opacity(0.4))
                            Spacer()
                            Text(round.fatigueLabel)
                                .font(.caption.bold())
                                .foregroundStyle(fatigueColor(round.fatigue_index))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.07))
                                    .frame(height: 10)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(LinearGradient(
                                        colors: [.green, .yellow, .orange, Color.jfRed],
                                        startPoint: .leading, endPoint: .trailing))
                                    .frame(
                                        width: geo.size.width * CGFloat(round.fatigue_index) / 100.0,
                                        height: 10)
                                    .animation(.easeOut(duration: 0.8), value: round.fatigue_index)
                            }
                        }
                        .frame(height: 10)

                        // 前半/後半コメント
                        if round.fatigue_index > 50 {
                            Text("後半に強度が大きく落ちた。インターバルを短くするか、有酸素を増やそう。")
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.3))
                                .padding(.top, 2)
                        } else if round.fatigue_index < 20 {
                            Text("最後まで強度を維持できた。次はペースを上げてみよう。")
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.3))
                                .padding(.top, 2)
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Button { dismiss() } label: {
                        Text("閉じる")
                            .font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(LinearGradient.jfRedGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.bottom, 8)
                }
                .padding(20)
            }
        }
    }

    private func metricCard(icon: String, color: Color, title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.jfTextPrimary)
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(Color.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 0..<30:  return .green
        case 30..<50: return Color(hex: "#4488ff")
        case 50..<70: return .orange
        default:      return Color.jfRed
        }
    }

    private func fatigueColor(_ index: Int) -> Color {
        switch index {
        case 0..<20:  return .green
        case 20..<45: return .yellow
        case 45..<70: return .orange
        default:      return Color.jfRed
        }
    }
}

// MARK: - Manual Round Sheet

private struct ManualRoundSheet: View {
    let elapsed: Int
    let onSave: (RoundSummary) -> Void
    @Environment(\.dismiss) private var dismiss

    private let levels: [(label: String, avg: UInt8, scrambles: UInt16)] = [
        ("軽め",    80, 1),
        ("普通",   115, 3),
        ("ハード", 145, 5),
        ("激しい", 175, 8),
        ("限界突破",210,12),
    ]
    @State private var selected = 2  // default: ハード

    var body: some View {
        ZStack {
            Color(hex: "#0d0d0d").ignoresSafeArea()
            VStack(spacing: 24) {
                Text("強度を選択")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                Text(timerStr)
                    .font(.system(size: 44, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.7))

                HStack(spacing: 10) {
                    ForEach(levels.indices, id: \.self) { i in
                        let lv = levels[i]
                        Button {
                            withAnimation(.spring(response: 0.3)) { selected = i }
                        } label: {
                            Text(lv.label)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(selected == i ? .black : .white)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(selected == i ? levelColor(i) : Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(.horizontal, 20)

                Button {
                    let lv = levels[selected]
                    let score = calcScore(avg: lv.avg, scrambles: lv.scrambles, dur: elapsed)
                    let json = """
                    {"dur_s":\(max(elapsed,10)),"avg_intensity":\(lv.avg),"peak_intensity":\(min(Int(lv.avg)+40,255)),"scrambles":\(lv.scrambles),"score":\(score),"fatigue_index":0}
                    """
                    if let d = json.data(using: .utf8),
                       let r = try? JSONDecoder().decode(RoundSummary.self, from: d) {
                        onSave(r)
                    }
                    dismiss()
                } label: {
                    Text("記録する")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient(colors: [Color(hex:"#cc2200"), Color(hex:"#991a00")],
                                                   startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 28)
        }
    }

    private var timerStr: String {
        String(format: "%d:%02d", elapsed / 60, elapsed % 60)
    }

    private func levelColor(_ i: Int) -> Color {
        [Color.green, Color(hex:"#4488ff"), Color.orange, Color(hex:"#ff4422"), Color(hex:"#ff0044")][i]
    }

    private func calcScore(avg: UInt8, scrambles: UInt16, dur: Int) -> Int {
        let ipts  = min(Float(avg) / 180.0 * 50.0, 50.0)
        let dmin  = max(Float(dur) / 60.0, 0.1)
        let spts  = min(Float(scrambles) / dmin * 5.0 / 10.0 * 30.0, 30.0)
        let dpts  = min(Float(dur) / 300.0 * 20.0, 20.0)
        return min(Int(ipts + spts + dpts), 100)
    }
}

// MARK: - Color extension

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}
