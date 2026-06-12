import AppIntents
import SwiftUI

struct LogPracticeIntent: AppIntent {
    static var title: LocalizedStringResource = "練習を記録"
    static var description = IntentDescription("JiuFlowで柔術の練習を記録します")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .jfOpenQuickLog, object: nil)
        return .result()
    }
}

struct ViewRankingsIntent: AppIntent {
    static var title: LocalizedStringResource = "ランキングを表示"
    static var description = IntentDescription("JiuFlowのランキングを表示します")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .jfOpenRankings, object: nil)
        return .result()
    }
}

struct JiuFlowShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogPracticeIntent(),
            phrases: [
                "JiuFlowで練習を記録",
                "柔術の練習を記録"
            ],
            shortTitle: "練習を記録",
            systemImageName: "figure.martial.arts"
        )
        AppShortcut(
            intent: ViewRankingsIntent(),
            phrases: [
                "JiuFlowのランキングを表示",
                "柔術ランキングを見せて"
            ],
            shortTitle: "ランキングを表示",
            systemImageName: "trophy.fill"
        )
    }
}

extension Notification.Name {
    static let jfOpenQuickLog = Notification.Name("jfOpenQuickLog")
    static let jfOpenRankings = Notification.Name("jfOpenRankings")
}
