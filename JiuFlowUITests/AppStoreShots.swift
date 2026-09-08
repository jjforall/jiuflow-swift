import XCTest

/// Captures App Store marketing screenshots in a given UI language.
/// Run per language on a simulator, then export attachments with
/// `xcrun xcresulttool export attachments`. See scripts/appstore_shots.sh.
///
/// The store pages currently show Japanese screenshots in every storefront
/// (only ja/en-US metadata exists), so BR/MX shoppers see a Japanese app.
/// These tests regenerate en / pt screenshots so each localization matches.
final class AppStoreShots: XCTestCase {

    override func setUpWithError() throws { continueAfterFailure = true }

    private func capture(_ lang: String) {
        let app = launchApp(LaunchConfig(language: lang))
        _ = app.navigationBars.firstMatch.waitForExistence(timeout: 15)
        sleep(2)
        snap(app, "\(lang)_01_home")

        tapTab(app, TabLabels.learn(lang)); sleep(2)
        snap(app, "\(lang)_02_learn")

        tapTab(app, TabLabels.train(lang)); sleep(2)
        snap(app, "\(lang)_03_train")

        tapTab(app, TabLabels.mypage(lang)); sleep(2)
        snap(app, "\(lang)_04_mypage")

        tapTab(app, TabLabels.home(lang)); sleep(1)
        if app.buttons["quickLogFab"].waitForExistence(timeout: 5) {
            app.buttons["quickLogFab"].tap(); sleep(2)
            snap(app, "\(lang)_05_log")
        }
    }

    func testShotsEN() throws { capture("en") }
    func testShotsPT() throws { capture("pt") }
}
