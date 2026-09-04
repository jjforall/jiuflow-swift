import XCTest

/// F-3 i18n: JiuFlow ships ja / en / pt. Rule (workspace): every UI string must be localized.
/// With the app forced to English, no Japanese text may remain on the five root screens.
final class I18nTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func testTabLabelsEnglish() throws {
        let app = launchApp(LaunchConfig(language: "en"))
        for l in TabLabels.all("en") {
            XCTAssertTrue(app.tabBars.buttons[l].exists, "EN tab '\(l)' missing")
        }
        XCTAssertTrue(app.navigationBars["JiuFlow"].waitForExistence(timeout: 10))
        snap(app, "20_home_en")
    }

    func testTabLabelsPortuguese() throws {
        let app = launchApp(LaunchConfig(language: "pt"))
        // pt falls back to en when no pt string is given (LanguageManager.t).
        for l in TabLabels.all("pt") {
            XCTAssertTrue(app.tabBars.buttons[l].exists, "PT tab '\(l)' missing")
        }
        snap(app, "21_home_pt")
    }

    func testNoJapaneseLeaksInEnglishMode() throws {
        let app = launchApp(LaunchConfig(language: "en"))
        var report: [String] = []
        var leaks = 0

        func scan(_ screen: String) {
            let jp = visibleLabels(app).filter { $0.containsJapanese }
            leaks += jp.count
            report.append("## \(screen): \(jp.count) Japanese strings")
            report += jp.map { "- \($0)" }
        }

        // Home
        _ = app.navigationBars["JiuFlow"].waitForExistence(timeout: 10)
        scan("Home")
        snap(app, "22_en_home")

        // Learn: 3 segments
        tapTab(app, "Learn")
        let seg = app.segmentedControls.firstMatch
        _ = seg.waitForExistence(timeout: 5)
        scan("Learn/segment0")
        snap(app, "23_en_learn")
        if seg.buttons.count == 3 {
            seg.buttons.element(boundBy: 1).tap(); sleep(1); scan("Learn/segment1")
            seg.buttons.element(boundBy: 2).tap(); sleep(1); scan("Learn/segment2")
        }

        // Train
        tapTab(app, "Train"); sleep(1)
        scan("Train")
        snap(app, "24_en_train")

        // My Page
        tapTab(app, "My Page"); sleep(1)
        scan("My Page")
        snap(app, "25_en_mypage")

        // Quick log sheet
        app.buttons["quickLogFab"].tap(); sleep(1)
        scan("QuickLog sheet")
        snap(app, "26_en_quicklog")

        attachText(report.joined(separator: "\n"), name: "i18n_leaks_en.md")
        XCTAssertEqual(leaks, 0, "\(leaks) Japanese strings visible in English mode — see attachment i18n_leaks_en.md")
    }

    func testLanguageSwitchFromMyPageOrSettingsIsReachable() throws {
        // The language control lives on My Page (logged-out/guest) or in Settings (logged-in).
        let app = launchApp(LaunchConfig(language: "ja"))
        tapTab(app, "マイページ")
        let langLabel = app.staticTexts["言語"]
        var found = scrollTo(langLabel, in: app, maxSwipes: 6)
        if !found {
            // Logged-in: My Page → 設定 → 言語
            let settings = app.buttons.containing(.staticText, identifier: "設定").firstMatch
            if scrollTo(settings, in: app, maxSwipes: 8) {
                settings.tap()
                found = app.navigationBars["設定"].waitForExistence(timeout: 5) && scrollTo(langLabel, in: app, maxSwipes: 6)
            }
        }
        XCTAssertTrue(found, "A '言語' (Language) control must be reachable from My Page")
        snap(app, "27_language_control")
    }
}
