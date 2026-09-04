import XCTest

/// F-2 Quick log: the center "+" opens the log sheet, each card opens its form, and everything
/// can be dismissed without saving (tests must never write to the tester's real journal).
final class QuickLogTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func testFabOpensQuickLogSheetAndCloses() throws {
        let app = launchApp()
        app.buttons["quickLogFab"].tap()

        XCTAssertTrue(app.navigationBars["記録する"].waitForExistence(timeout: 5), "Quick log sheet title")
        XCTAssertTrue(app.staticTexts["何を記録する？"].exists)
        for card in ["練習を記録", "スパーリングを記録", "体重を記録", "大会結果を記録", "動画メモ"] {
            XCTAssertTrue(app.staticTexts[card].exists || app.buttons[card].exists, "Card '\(card)' missing")
        }
        XCTAssertTrue(app.staticTexts["ワンタップ記録"].exists, "One-tap section")
        snap(app, "10_quicklog_sheet")

        app.navigationBars["記録する"].buttons["閉じる"].tap()
        XCTAssertTrue(app.navigationBars["記録する"].waitForNonExistence(timeout: 5), "Sheet should close")
    }

    func testLogTabItemAlsoOpensSheet() throws {
        let app = launchApp()
        // The "記録" tab item is a placeholder that re-selects the previous tab and opens the sheet.
        tapTab(app, "記録")
        XCTAssertTrue(app.navigationBars["記録する"].waitForExistence(timeout: 5), "Tab '記録' should open the sheet")
        app.navigationBars["記録する"].buttons["閉じる"].tap()
        XCTAssertTrue(app.navigationBars["記録する"].waitForNonExistence(timeout: 5))
        // Previous tab (Home) must still be selected.
        XCTAssertTrue(app.tabBars.buttons["ホーム"].isSelected, "Home should remain selected after closing the sheet")
    }

    func testPracticeCardOpensNewEntryFormWithoutSaving() throws {
        let app = launchApp()
        app.buttons["quickLogFab"].tap()
        XCTAssertTrue(app.navigationBars["記録する"].waitForExistence(timeout: 5))

        let card = app.buttons.containing(.staticText, identifier: "練習を記録").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 3), "練習を記録 card")
        card.tap()

        XCTAssertTrue(app.navigationBars["新しい記録"].waitForExistence(timeout: 5), "New journal entry form")
        snap(app, "11_quicklog_practice_form")

        // Dismiss the form sheet by swiping it down; nothing is saved.
        app.swipeDown(velocity: .fast)
        if app.navigationBars["新しい記録"].waitForNonExistence(timeout: 3) == false {
            // Fallback: use a cancel/close button if present.
            let bar = app.navigationBars["新しい記録"]
            let cancel = bar.buttons.allElementsBoundByIndex.first { ["キャンセル", "閉じる", "Cancel"].contains($0.label) }
            cancel?.tap()
        }
        XCTAssertTrue(app.navigationBars["新しい記録"].waitForNonExistence(timeout: 5), "Form should be dismissed")
    }
}
