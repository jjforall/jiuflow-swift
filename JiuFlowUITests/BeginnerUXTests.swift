import XCTest

/// Beginner-persona exploratory tests: a brand-new user walks the videos tab
/// and reports every friction point. Findings are attached as text.
final class BeginnerUXTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    /// A beginner opens the 動画 tab and tries to (1) understand what to watch,
    /// (2) find the newest class video, (3) change sort order, (4) play a video.
    func testBeginnerVideosJourney() throws {
        let app = launchApp(LaunchConfig(language: "ja"))
        var findings: [String] = []

        // --- 動画タブを開く
        let videosTab = app.tabBars.buttons["動画"]
        XCTAssertTrue(videosTab.waitForExistence(timeout: 15))
        videosTab.tap()
        XCTAssertTrue(app.navigationBars["動画"].waitForExistence(timeout: 10))
        snap(app, "b01_videos_top")

        // --- フィードが出るまで待つ
        let firstCard = app.buttons["videoFeedCard"].firstMatch
        guard firstCard.waitForExistence(timeout: 25) else {
            throw XCTSkip("feed unavailable")
        }

        // --- 観察1: 並び替えチップは見えるか？
        let sortChips = ["新着順", "人気順", "古い順"]
        var visibleChips: [String] = []
        for label in sortChips {
            if app.buttons[label].exists { visibleChips.append(label) }
        }
        findings.append("並び替えチップ表示: \(visibleChips.joined(separator: ",")) (\(visibleChips.count)/3)")

        // --- 観察2: カテゴリチップは見えるか
        let catChips = ["すべて", "ガード", "パス", "バック", "極め技", "スイープ", "テイクダウン"]
        var visibleCat: [String] = []
        for label in catChips {
            if app.buttons[label].exists { visibleCat.append(label) }
        }
        findings.append("カテゴリチップ表示: \(visibleCat.count)/7")

        // --- 観察3: 新着セクションはあるか（カタログに14日以内の投稿がないので出ないはず）
        let hasNew = app.staticTexts["新着"].exists
        findings.append("新着セクション: \(hasNew ? "表示" : "非表示（14日以内の投稿なし）")")

        // --- 観察4: 先頭カードの中身（タイトル・日付）を取得
        let cardLabels = firstCard.staticTexts.allElementsBoundByIndex.map { $0.label }.filter { !$0.isEmpty }
        findings.append("先頭カード内テキスト: \(cardLabels.joined(separator: " / "))")

        // --- 観察5: カードに日付表示があるか（いつ撮られた動画か分かるか）
        let dateLike = app.staticTexts.matching(NSPredicate(format: "label MATCHES '.*20[0-9]{2}[./年].*'"))
        findings.append("日付らしき表示: \(dateLike.count)件")

        // --- 観察6: 古い順に切替
        if app.buttons["古い順"].exists {
            app.buttons["古い順"].tap()
            sleep(1)
            snap(app, "b02_oldest")
            let oldestFirst = app.buttons["videoFeedCard"].firstMatch
            let oldestLabels = oldestFirst.staticTexts.allElementsBoundByIndex.map { $0.label }.filter { !$0.isEmpty }
            findings.append("古い順先頭カード内テキスト: \(oldestLabels.joined(separator: " / "))")
            app.buttons["新着順"].tap()
            sleep(1)
        }

        // --- 観察7: 詳細を開く
        firstCard.tap()
        sleep(2)
        snap(app, "b03_detail")
        let detailTexts = app.staticTexts.allElementsBoundByIndex.map { $0.label }.filter { !$0.isEmpty }
        findings.append("詳細画面テキスト数: \(detailTexts.count)")
        let hasPlayControl = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'play' OR label CONTAINS '再生'")).count > 0
        findings.append("再生コントロールらしきもの: \(hasPlayControl ? "あり" : "不明")")

        // --- 観察8: 戻る
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["動画"].waitForExistence(timeout: 10))

        // --- 観察9: 続きから見るが出たか
        let hasContinue = app.staticTexts["続きから見る"].waitForExistence(timeout: 5)
        findings.append("続きから見る: \(hasContinue ? "表示" : "非表示")")
        snap(app, "b04_after_watch")

        attachText(findings.joined(separator: "\n"), name: "beginner_findings.md")
    }
}
