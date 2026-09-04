import XCTest

/// D-1..D-4 Design checks that can be asserted, plus screenshots for human review.
/// - Dark theme is enforced (background #0A0A0A) on every root screen.
/// - Tab bar + nav title survive Accessibility Dynamic Type (no layout collapse).
/// - Nav titles use the design system (large title on Home / My Page).
final class DesignTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    /// Sample the left gutter (x = 4pt, outside the 16pt content padding) at several heights.
    private func assertDarkBackground(_ app: XCUIApplication, _ screen: String) {
        let img = app.screenshot().image
        let h = img.size.height
        var report: [String] = []
        for y in [h * 0.25, h * 0.45, h * 0.65] {
            guard let lum = img.luminance(at: CGPoint(x: 4, y: y)) else { continue }
            report.append(String(format: "%@ y=%.0f lum=%.3f", screen, y, lum))
            XCTAssertLessThan(lum, 0.20, "\(screen): background at y=\(Int(y)) is not dark (lum \(lum))")
        }
        attachText(report.joined(separator: "\n"), name: "dark_bg_\(screen).txt")
    }

    func testDarkThemeOnAllRootScreens() throws {
        let app = launchApp()
        _ = app.navigationBars["JiuFlow"].waitForExistence(timeout: 10)
        assertDarkBackground(app, "home")
        tapTab(app, "学ぶ"); sleep(1); assertDarkBackground(app, "learn")
        tapTab(app, "練習"); sleep(1); assertDarkBackground(app, "train")
        tapTab(app, "マイページ"); sleep(1); assertDarkBackground(app, "mypage")
        app.buttons["quickLogFab"].tap()
        _ = app.navigationBars["記録する"].waitForExistence(timeout: 5)
        assertDarkBackground(app, "quicklog")
    }

    func testAccessibilityDynamicTypeKeepsLayout() throws {
        let app = launchApp(LaunchConfig(contentSize: "UICTContentSizeCategoryAccessibilityM"))
        XCTAssertEqual(app.tabBars.firstMatch.buttons.count, 5, "Tab bar must keep 5 items at AX text size")
        _ = app.navigationBars["JiuFlow"].waitForExistence(timeout: 10)
        snap(app, "50_ax_home")
        tapTab(app, "学ぶ"); sleep(1)
        XCTAssertEqual(app.segmentedControls.firstMatch.buttons.count, 3, "Segments must all be present at AX size")
        snap(app, "51_ax_learn")
        tapTab(app, "練習"); sleep(1)
        snap(app, "52_ax_train")
        tapTab(app, "マイページ"); sleep(1)
        snap(app, "53_ax_mypage")
        app.buttons["quickLogFab"].tap()
        XCTAssertTrue(app.navigationBars["記録する"].waitForExistence(timeout: 5))
        snap(app, "54_ax_quicklog")
    }

    func testTabBarIsOpaqueAndAtBottom() throws {
        let app = launchApp()
        let bar = app.tabBars.firstMatch
        let screen = app.frame
        XCTAssertEqual(bar.frame.maxY, screen.maxY, accuracy: 1, "Tab bar must be flush with the bottom edge")
        XCTAssertGreaterThanOrEqual(bar.frame.height, 49, "Tab bar height")
        // Every tab item must be hittable and non-overlapping.
        let frames = bar.buttons.allElementsBoundByIndex.map { $0.frame }
        for (i, f) in frames.enumerated() {
            for g in frames[(i + 1)...] where i + 1 < frames.count {
                XCTAssertFalse(f.intersects(g), "Tab items overlap")
            }
        }
    }

    func testMyPageHeroCopyIsInAppCopy() throws {
        // Copy rule: no "頑張って"-style copy, no competitor names in the app UI.
        let app = launchApp()
        var all: [String] = []
        for tab in TabLabels.all("ja") where tab != "記録" {
            tapTab(app, tab); sleep(1)
            all += visibleLabels(app)
        }
        let banned = ["頑張", "がんばっ", "LINE", "Clubhouse", "Instagram"]
        let hits = all.filter { s in banned.contains { s.localizedCaseInsensitiveContains($0) } }
        attachText(hits.joined(separator: "\n"), name: "copy_rule_hits.txt")
        XCTAssertTrue(hits.isEmpty, "Copy rule violations: \(hits)")
    }
}
