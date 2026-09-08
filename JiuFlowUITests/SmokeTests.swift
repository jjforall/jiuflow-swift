import XCTest

/// F-1 Smoke: the app launches, all five tabs exist and each root screen renders.
final class SmokeTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    func testAllTabsRenderJa() throws {
        let app = launchApp(LaunchConfig(language: "ja"))
        let labels = TabLabels.all("ja")

        XCTAssertEqual(app.tabBars.firstMatch.buttons.count, 5, "Tab bar should have 5 items")
        for l in labels {
            XCTAssertTrue(app.tabBars.buttons[l].exists, "Tab '\(l)' missing (ja)")
        }

        // Home
        XCTAssertTrue(app.navigationBars["JiuFlow"].waitForExistence(timeout: 10), "Home nav title 'JiuFlow'")
        snap(app, "01_home_ja")

        // Learn (segmented: フロー/動画/プラン)
        tapTab(app, TabLabels.learn("ja"))
        let seg = app.segmentedControls.firstMatch
        XCTAssertTrue(seg.waitForExistence(timeout: 5), "Learn segmented control")
        XCTAssertEqual(seg.buttons.count, 3, "Learn should have 3 segments")
        snap(app, "02_learn_flow_ja")
        seg.buttons["動画"].tap()
        XCTAssertTrue(seg.buttons["動画"].isSelected)
        snap(app, "03_learn_videos_ja")
        seg.buttons["プラン"].tap()
        XCTAssertTrue(seg.buttons["プラン"].isSelected)
        snap(app, "04_learn_plans_ja")

        // Train
        tapTab(app, TabLabels.train("ja"))
        XCTAssertTrue(app.staticTexts["トレーニング"].waitForExistence(timeout: 5), "Train header")
        XCTAssertTrue(app.buttons["ラウンドを開始"].exists || app.staticTexts["ラウンドを開始"].exists,
                      "Manual 'ラウンドを開始' entry point must exist when no HR device")
        snap(app, "05_train_ja")

        // My Page
        tapTab(app, TabLabels.mypage("ja"))
        XCTAssertTrue(app.navigationBars["マイページ"].waitForExistence(timeout: 5), "My Page nav title")
        snap(app, "06_mypage_ja")

        // Back to Home keeps state
        tapTab(app, TabLabels.home("ja"))
        XCTAssertTrue(app.navigationBars["JiuFlow"].waitForExistence(timeout: 5))
    }

    func testFloatingLogButtonExistsAndDoesNotOverlapFeedbackButton() throws {
        let app = launchApp()
        let fab = app.buttons["quickLogFab"]
        XCTAssertTrue(fab.waitForExistence(timeout: 5), "Floating + (quickLogFab) must exist")
        XCTAssertTrue(fab.isHittable, "FAB must be hittable")

        // Design: FAB (56pt) must be centered horizontally over the tab bar.
        let screen = app.frame
        XCTAssertEqual(fab.frame.midX, screen.midX, accuracy: 4, "FAB should be horizontally centered")
        XCTAssertGreaterThan(fab.frame.minY, screen.height * 0.8, "FAB should sit at the bottom of the screen")

        // Design: the feedback bubble (bottom-trailing overlay) must not overlap the FAB.
        let feedback = app.buttons.allElementsBoundByIndex.first {
            $0.frame.width <= 60 && $0.frame.maxX > screen.width - 8 - 60 && $0.frame.midY < fab.frame.minY && $0.frame.midY > screen.height * 0.75
        }
        if let fb = feedback {
            XCTAssertFalse(fb.frame.intersects(fab.frame), "Feedback bubble overlaps the FAB")
        }
        snap(app, "07_home_fab")
    }

    func testLaunchPerformance() throws {
        // Design KPI: cold-ish launch to first frame. Runs 5 iterations.
        let app = XCUIApplication()
        LaunchConfig().apply(to: app)
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
}
