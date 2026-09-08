import Foundation

struct WidgetData: Codable {
    var streak: Int
    var thisWeekCount: Int
    var weeklyGoal: Int
    var nextTournamentName: String?
    var nextTournamentDate: String?
}

struct TournamentsResponse: Codable {
    let tournaments: [WidgetTournament]
}

struct WidgetTournament: Codable {
    let name: String?
    let name_ja: String?
    let date: String?
    let date_start: String?
}

extension WidgetData {
    static func placeholder() -> WidgetData {
        WidgetData(streak: 0, thisWeekCount: 0, weeklyGoal: 3)
    }

    static func fetch() async -> WidgetData {
        var data = WidgetData.placeholder()
        guard let url = URL(string: "https://jiuflow-ssr.fly.dev/api/v1/tournaments") else { return data }
        if let (raw, _) = try? await URLSession.shared.data(from: url),
           let resp = try? JSONDecoder().decode(TournamentsResponse.self, from: raw) {
            let today = Date()
            let fmt = ISO8601DateFormatter()
            fmt.formatOptions = [.withFullDate]
            let upcoming = resp.tournaments
                .compactMap { t -> (String, Date)? in
                    let dateStr = t.date_start ?? t.date ?? ""
                    guard let d = fmt.date(from: dateStr), d > today else { return nil }
                    return (t.name_ja ?? t.name ?? dateStr, d)
                }
                .sorted { $0.1 < $1.1 }
                .first
            if let (name, date) = upcoming {
                data.nextTournamentName = name
                let display = DateFormatter()
                display.locale = Locale(identifier: "ja_JP")
                display.dateFormat = "M/d(E)"
                data.nextTournamentDate = display.string(from: date)
            }
        }
        return data
    }
}
