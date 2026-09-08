import XCTest

/// F-5 Onboarding: first launch shows the onboarding cover; skip and page-through both reach the main UI.
final class OnboardingTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func testFirstLaunchShowsOnboardingAndSkipWorks() throws {
        let app = launchApp(LaunchConfig(seenOnboarding: false), waitForTabBar: false)
        let skip = app.buttons["スキップ"]
        XCTAssertTrue(skip.waitForExistence(timeout: 10), "Onboarding must appear on first launch")
        XCTAssertTrue(app.buttons["次へ"].exists, "'次へ' button on first page")
        snap(app, "40_onboarding_page1")
        skip.tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "Main UI after skip")
    }

    func testOnboardingPagesThroughToStart() throws {
        let app = launchApp(LaunchConfig(seenOnboarding: false), waitForTabBar: false)
        XCTAssertTrue(app.buttons["スキップ"].waitForExistence(timeout: 10))
        var pages = 1
        while app.buttons["次へ"].exists && pages < 10 {
            app.buttons["次へ"].tap()
            pages += 1
            snap(app, "41_onboarding_page\(pages)")
        }
        let start = app.buttons["はじめる"]
        XCTAssertTrue(start.waitForExistence(timeout: 3), "Last page shows 'はじめる'")
        XCTAssertGreaterThanOrEqual(pages, 2, "Onboarding should have at least 2 pages")
        start.tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "Main UI after finishing onboarding")
    }

    func testReturningUserSkipsOnboarding() throws {
        let app = launchApp(LaunchConfig(seenOnboarding: true))
        XCTAssertFalse(app.buttons["スキップ"].exists, "Onboarding must not show for returning users")
    }
}
