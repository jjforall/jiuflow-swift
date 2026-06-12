import Foundation

struct WidgetData: Codable {
    var streak: Int
    var thisWeekCount: Int
    var weeklyGoal: Int
    var nextTournamentName: String?
    var nextTournamentDate: String?
    var lastPracticeDate: Date?
}

extension WidgetData {
    static func load() -> WidgetData {
        guard let data = UserDefaults.standard.data(forKey: "widget_data"),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data)
        else { return WidgetData(streak: 0, thisWeekCount: 0, weeklyGoal: 3) }
        return decoded
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "widget_data")
        }
    }
}
