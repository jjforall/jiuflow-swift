import Foundation

// CTL/ATL/TSB Training Load Model (derived from cycling/triathlon fitness science)
//
//   CTL (Chronic Training Load)  = 42-day EMA of daily score → "fitness"
//   ATL (Acute Training Load)    =  7-day EMA of daily score → "fatigue"
//   TSB (Training Stress Balance)= CTL - ATL                → "form / readiness"
//
// Positive TSB = more fit than fatigued → good for competition
// Negative TSB = more fatigued than fit → needs recovery

@MainActor
final class TrainingLoadManager: ObservableObject {

    @Published private(set) var ctl:   Double = 0
    @Published private(set) var atl:   Double = 0
    @Published private(set) var tsb:   Double = 0
    @Published private(set) var trend: [DayLoad] = []

    struct DayLoad: Identifiable {
        let id:    String   // "yyyy-MM-dd"
        let score: Int
        let ctl:   Double
        let atl:   Double
    }

    private let historyKey = "jf_daily_score_v1"

    private var history: [String: Int] {
        get { (UserDefaults.standard.dictionary(forKey: historyKey) as? [String: Int]) ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: historyKey) }
    }

    init() { recompute() }

    // Record today's best score (idempotent — keeps maximum)
    func record(score: Int, on date: Date = .now) {
        guard score > 0 else { return }
        let key = dayKey(date)
        var h = history
        h[key] = max(h[key] ?? 0, score)
        history = h
        recompute()
    }

    func recompute() {
        let cal      = Calendar.current
        let today    = Date.now
        let aCtl     = 2.0 / (42.0 + 1.0)
        let aAtl     = 2.0 / (7.0 + 1.0)
        var ctlV     = 0.0
        var atlV     = 0.0
        var days: [DayLoad] = []

        for offset in stride(from: -59, through: 0, by: 1) {
            guard let d = cal.date(byAdding: .day, value: offset, to: today) else { continue }
            let s  = Double(history[dayKey(d)] ?? 0)
            ctlV   = s * aCtl + ctlV * (1.0 - aCtl)
            atlV   = s * aAtl + atlV * (1.0 - aAtl)
            days.append(DayLoad(id: dayKey(d), score: Int(s), ctl: ctlV, atl: atlV))
        }

        ctl   = round10(ctlV)
        atl   = round10(atlV)
        tsb   = round10(ctlV - atlV)
        trend = Array(days.suffix(14))
    }

    // MARK: - Labels

    var formLabel: String {
        switch tsb {
        case ..<(-15): return "疲労困憊"
        case -15 ..< -5: return "疲労中"
        case -5 ..< 5:   return "ニュートラル"
        case 5 ..< 15:   return "好調"
        default:         return "ピーク状態"
        }
    }

    var formColor: FormColor {
        switch tsb {
        case ..<(-10): return .red
        case -10 ..< -3: return .orange
        case -3 ..< 5:   return .white
        case 5 ..< 15:   return .blue
        default:         return .green
        }
    }

    var advice: String {
        switch tsb {
        case ..<(-15): return "休養必須 — オーバートレーニングに注意"
        case -15 ..< -5: return "強度を落として回復を優先しよう"
        case -5 ..< 5:   return "バランス良好 — このペースで継続"
        case 5 ..< 15:   return "試合前週に最適なコンディション"
        default:         return "ピーク！今が試合のベストタイミング"
        }
    }

    enum FormColor { case red, orange, white, blue, green }

    // MARK: - Private

    private func round10(_ v: Double) -> Double { (v * 10).rounded() / 10 }

    private static let dayFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private func dayKey(_ date: Date) -> String {
        Self.dayFmt.string(from: date)
    }
}
