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

    /// 6. Sort order control: 新着順/人気順/古い順 chips exist, and switching to
    /// 古い順 puts the oldest video first in the feed.
    func testSortOrderChips() throws {
        let app = launchApp(LaunchConfig(language: "ja"))
        openVideosTab(app)
        XCTAssertTrue(app.navigationBars["動画"].waitForExistence(timeout: 10))

        for label in ["新着順", "人気順", "古い順"] {
            XCTAssertTrue(app.buttons[label].waitForExistence(timeout: 10),
                          "Sort chip '\(label)' missing")
        }

        // Default is 新着順: newest upload (2026.8.30 サマークラス) leads the feed.
        let firstCard = app.buttons["videoFeedCard"].firstMatch
        guard firstCard.waitForExistence(timeout: 25) else {
            throw XCTSkip("Video feed unavailable (offline or empty); cannot verify ordering")
        }
        snap(app, "v08_sort_newest")

        // Switch to 古い順: the oldest tutorial must now lead.
        app.buttons["古い順"].tap()
        sleep(1)
        let oldestFirst = app.buttons["videoFeedCard"].firstMatch
        XCTAssertTrue(oldestFirst.waitForExistence(timeout: 10))
        // The oldest tutorial in the catalog is a 2025-11 クローズドガード video,
        // and it must be the FIRST card, not just somewhere on screen.
        let firstCardLabel = oldestFirst.staticTexts
            .matching(NSPredicate(format: "label CONTAINS 'クローズドガード'"))
            .firstMatch
        XCTAssertTrue(firstCardLabel.exists,
                      "古い順 should put a 2025-11 クローズドガード video in the first feed card")
        snap(app, "v09_sort_oldest")

        // 人気順 should also keep a populated feed.
        app.buttons["人気順"].tap()
        sleep(1)
        XCTAssertTrue(app.buttons["videoFeedCard"].firstMatch.waitForExistence(timeout: 10),
                      "人気順 should keep a populated feed")
        snap(app, "v10_sort_popular")
    }

    /// 7. 新着 (last-14-days) row appears above the feed when recent uploads exist.
    /// The skip decision comes from an independent fetch of the same API the app
    /// uses. Fetch/parse failures FAIL the test; only a successfully parsed
    /// catalog with no tutorial uploads in the window skips.
    func testNewArrivalsSection() throws {
        // Independent API check comes FIRST: only a successfully parsed catalog
        // with no recent tutorial uploads may skip. If the catalog HAS recent
        // uploads, a missing feed or missing 新着 row is a test failure.
        let hasRecent = try fetchCatalogHasRecentTutorialUpload()
        guard hasRecent else {
            throw XCTSkip("Catalog verified via API: no tutorial uploads within 14 days; 新着 row hidden by design")
        }

        let app = launchApp(LaunchConfig(language: "ja"))
        openVideosTab(app)
        XCTAssertTrue(app.navigationBars["動画"].waitForExistence(timeout: 10))

        XCTAssertTrue(app.buttons["videoFeedCard"].firstMatch.waitForExistence(timeout: 25),
                      "Catalog has recent uploads, so the feed must populate")
        XCTAssertTrue(app.staticTexts["新着"].waitForExistence(timeout: 10),
                      "Catalog has tutorial uploads within 14 days, so the 新着 row must be visible")
        snap(app, "v11_new_arrivals")
    }

    /// Fetch the production videos API and check for tutorial uploads in the
    /// last 14 days. Throws on network/JSON/date-parse failure so a broken
    /// pipeline fails the test instead of silently skipping it.
    private func fetchCatalogHasRecentTutorialUpload() throws -> Bool {
        let url = URL(string: "https://jiuflow-ssr.fly.dev/api/v1/videos")!
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            XCTFail("新着 row verification: failed to fetch videos API: \(error.localizedDescription)")
            throw error
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let videos = json["videos"] as? [[String: Any]] else {
            XCTFail("新着 row verification: videos API JSON shape unexpected")
            throw NSError(domain: "VideoTabTests", code: 1)
        }
        let cutoff = Date().addingTimeInterval(-14 * 24 * 3600)
        let isoFractional = ISO8601DateFormatter()
        isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoPlain = ISO8601DateFormatter()
        isoPlain.formatOptions = [.withInternetDateTime]
        let simple = DateFormatter()
        simple.dateFormat = "yyyy-MM-dd"
        simple.locale = Locale(identifier: "en_US_POSIX")
        simple.timeZone = TimeZone(secondsFromGMT: 0)

        for raw in videos where (raw["video_type"] as? String) == "tutorial" {
            guard let ts = raw["created_at"] as? String else {
                XCTFail("新着 row verification: tutorial video has non-string created_at: \(raw["id"] ?? "?")")
                throw NSError(domain: "VideoTabTests", code: 2)
            }
            guard let date = isoFractional.date(from: ts)
                ?? isoPlain.date(from: ts)
                ?? simple.date(from: String(ts.prefix(10))) else {
                XCTFail("新着 row verification: unparseable created_at '\(ts)'")
                throw NSError(domain: "VideoTabTests", code: 3)
            }
            if date >= cutoff { return true }
        }
        return false
    }
}
