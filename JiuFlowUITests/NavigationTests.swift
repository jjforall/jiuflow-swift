import XCTest

/// F-4 Navigation + live data: My Page → Tournaments loads real data from jiuflow-ssr,
/// My Page → Settings shows the language picker and app version. Skips when the tester is not logged in
/// (those menus only exist in LoggedInContentView).
final class NavigationTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    /// Returns true when the My Page shows the logged-in menu, false for login/guest screens.
    private func openMyPageLoggedIn(_ app: XCUIApplication) -> Bool {
        tapTab(app, "マイページ")
        _ = app.navigationBars["マイページ"].waitForExistence(timeout: 5)
        if app.buttons["ゲストモードで閲覧"].exists { return false }
        if app.staticTexts["ゲストモード"].exists { return false }
        return true
    }

    func testTournamentsListLoadsFromServer() throws {
        let app = launchApp()
        guard openMyPageLoggedIn(app) else {
            snap(app, "30_mypage_logged_out")
            throw XCTSkip("Tester is not logged in on this device — tournaments menu unavailable")
        }
        let row = app.buttons.containing(.staticText, identifier: "大会一覧").firstMatch
        XCTAssertTrue(scrollTo(row, in: app), "大会一覧 menu row")
        row.tap()

        XCTAssertTrue(app.navigationBars["大会情報"].waitForExistence(timeout: 5), "Tournaments nav title")
        // Loading indicator must disappear within 20s (network → jiuflow-ssr.fly.dev).
        let loading = app.staticTexts["大会データを読み込み中..."]
        if loading.exists {
            XCTAssertTrue(loading.waitForNonExistence(timeout: 20), "Tournament data still loading after 20s")
        }
        XCTAssertFalse(app.staticTexts["該当する大会がありません"].exists, "Tournament list came back empty")
        XCTAssertTrue(app.searchFields.firstMatch.exists, "Search field on tournaments")
        snap(app, "31_tournaments")
    }

    func testSettingsShowsLanguagePickerAndVersion() throws {
        let app = launchApp()
        guard openMyPageLoggedIn(app) else {
            throw XCTSkip("Tester is not logged in on this device — settings menu unavailable")
        }
        let row = app.buttons.containing(.staticText, identifier: "設定").firstMatch
        XCTAssertTrue(scrollTo(row, in: app, maxSwipes: 10), "設定 menu row")
        row.tap()
        XCTAssertTrue(app.navigationBars["設定"].waitForExistence(timeout: 5), "Settings nav title")

        let lang = app.staticTexts["言語"]
        XCTAssertTrue(scrollTo(lang, in: app), "言語 row in settings")
        snap(app, "32_settings")

        // Version string like "1.1.1" must be shown somewhere in settings.
        let version = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", ".*\\d+\\.\\d+(\\.\\d+)?.*")).firstMatch
        XCTAssertTrue(scrollTo(version, in: app, maxSwipes: 6), "App version visible in settings")
    }

    func testTrainTabManualRoundEntryOpensIntensityPicker() throws {
        let app = launchApp()
        tapTab(app, "練習")
        let start = app.buttons.containing(.staticText, identifier: "ラウンドを開始").firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 5), "ラウンドを開始")
        start.tap()
        // Start → the same button turns into a running m:ss timer.
        sleep(2)
        let timer = app.buttons.matching(NSPredicate(format: "label MATCHES %@", ".*\\d+:\\d\\d.*")).firstMatch
        XCTAssertTrue(timer.waitForExistence(timeout: 5), "Manual round timer should be running after start")
        snap(app, "33_train_round_running")
        // Stop → intensity chooser sheet ("強度を選択"); only its "記録する" button saves.
        timer.tap()
        let picker = app.staticTexts["強度を選択"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "Intensity picker should open on stop")
        XCTAssertTrue(app.buttons["記録する"].exists, "記録する button in picker")
        snap(app, "34_train_intensity_picker")
        // Dismiss without recording.
        app.swipeDown(velocity: .fast)
        if !picker.waitForNonExistence(timeout: 3) {
            app.buttons["閉じる"].firstMatch.tap()
        }
        XCTAssertTrue(picker.waitForNonExistence(timeout: 5), "Picker dismissed without saving")
    }
}
