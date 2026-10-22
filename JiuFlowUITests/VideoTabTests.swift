import XCTest

/// QA tests for the feature/video-access-improve branch:
/// root 動画 tab, category filters, search, continue-watching, favorites, fullscreen.
final class VideoTabTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    private func openVideosTab(_ app: XCUIApplication) {
        let videosTab = app.tabBars.buttons["動画"]
        XCTAssertTrue(videosTab.waitForExistence(timeout: 10), "動画 tab must exist in the tab bar")
        videosTab.tap()
    }

    /// 1. Root tab bar has a 動画 tab that shows the videos feed directly.
    func testVideosTabExistsAndShowsFeed() throws {
        let app = launchApp(LaunchConfig(language: "ja"))
        openVideosTab(app)
        XCTAssertTrue(app.navigationBars["動画"].waitForExistence(timeout: 10),
                      "動画 tab should show the videos feed with nav title 動画")
        snap(app, "v01_videos_tab")
    }

    /// 2. Category filter chips exist and filter the list.
    func testCategoryFilterChips() throws {
        let app = launchApp(LaunchConfig(language: "ja"))
        openVideosTab(app)
        XCTAssertTrue(app.navigationBars["動画"].waitForExistence(timeout: 10))

        let all = app.buttons["すべて"]
        XCTAssertTrue(all.waitForExistence(timeout: 10), "すべて chip must exist")
        for chip in ["ガード", "パス", "バック", "極め技", "スイープ", "テイクダウン"] {
            XCTAssertTrue(app.buttons[chip].exists, "Chip '\(chip)' missing")
        }
        app.buttons["ガード"].tap()
        snap(app, "v02_filter_guard")
        app.buttons["すべて"].tap()
        snap(app, "v03_filter_all")
    }

    /// 3. Search field exists and filters.
    func testSearchField() throws {
        let app = launchApp(LaunchConfig(language: "ja"))
        openVideosTab(app)
        XCTAssertTrue(app.navigationBars["動画"].waitForExistence(timeout: 10))

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 10), "Search field must exist on 動画 tab")
        searchField.tap()
        searchField.typeText("zzz-no-such-video")
        // With a nonsense query the empty state should appear (regardless of network).
        XCTAssertTrue(app.staticTexts["動画が見つかりません"].waitForExistence(timeout: 10),
                      "Nonsense search should show the empty state")
        snap(app, "v04_search_empty")
        let cancel = app.buttons.matching(NSPredicate(format: "label IN {'Cancel', 'キャンセル'}")).firstMatch
        if cancel.exists { cancel.tap() }
    }

    /// 4+5. Open a video detail, toggle favorite heart, go back, and
    /// the 続きから見る section appears at the top of the videos tab.
    func testDetailFavoriteAndContinueWatching() throws {
        let app = launchApp(LaunchConfig(language: "ja"))
        openVideosTab(app)
        XCTAssertTrue(app.navigationBars["動画"].waitForExistence(timeout: 10))

        // Wait for the feed to load; skip gracefully if offline/empty.
        let firstCard = app.buttons["videoFeedCard"].firstMatch
        guard firstCard.waitForExistence(timeout: 25) else {
            snap(app, "v05_feed_unavailable")
            throw XCTSkip("Video feed unavailable (offline or empty); cannot exercise detail flow")
        }
        XCTAssertTrue(firstCard.isHittable, "Feed card should be hittable")
        firstCard.tap()
        // Fallback: if the tap didn't navigate (no detail title), tap the card's
        // center coordinate directly.
        if !app.staticTexts["2026.8.30 サマークラス"].waitForExistence(timeout: 5) {
            firstCard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)).tap()
        }
        sleep(2)
        snap(app, "v05b_after_tap")
        print("LABELS AFTER TAP:", visibleLabels(app))

        // Detail screen must appear (video title is shown).
        XCTAssertTrue(app.staticTexts["2026.8.30 サマークラス"].waitForExistence(timeout: 10),
                      "Video detail should open after tapping a feed card")
        snap(app, "v05c_detail")

        // Heart toggle in the toolbar (identified via accessibilityIdentifier).
        let fav = app.buttons["favoriteButton"].firstMatch
        XCTAssertTrue(fav.waitForExistence(timeout: 10), "Favorite heart button must exist in detail toolbar")
        fav.tap()
        snap(app, "v06_detail_favorited")

        // Back to the feed.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["動画"].waitForExistence(timeout: 10))

        // 続きから見る section should now be visible at the top.
        XCTAssertTrue(app.staticTexts["続きから見る"].waitForExistence(timeout: 10),
                      "続きから見る section must appear after watching a video")
        snap(app, "v07_continue_watching")
    }
}
