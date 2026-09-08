import XCTest

/// Launch configuration for the app under test.
/// Values are injected through NSArgumentDomain (`-key value`), so they override
/// `@AppStorage` for this launch only and never touch the user's stored settings.
struct LaunchConfig {
    var language: String = "ja"          // ja / en / pt
    var seenOnboarding: Bool = true
    var contentSize: String? = nil       // e.g. "UICTContentSizeCategoryAccessibilityM"

    func apply(to app: XCUIApplication) {
        app.launchArguments += [
            "-preferred_language", language,
            "-hasSeenOnboarding", seenOnboarding ? "YES" : "NO",
            "-AppleLanguages", "(\(language))",
        ]
        if let size = contentSize {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", size]
        }
    }
}

/// Tab bar labels per language (mirrors ContentView.swift).
enum TabLabels {
    static func all(_ lang: String) -> [String] {
        switch lang {
        case "en", "pt": return ["Home", "Learn", "Log", "Train", "My Page"]
        default:         return ["ホーム", "学ぶ", "記録", "練習", "マイページ"]
        }
    }
    static func home(_ l: String) -> String { all(l)[0] }
    static func learn(_ l: String) -> String { all(l)[1] }
    static func train(_ l: String) -> String { all(l)[3] }
    static func mypage(_ l: String) -> String { all(l)[4] }
}

extension XCTestCase {
    /// Launch with the given config and wait for the tab bar (= main UI is up).
    @discardableResult
    func launchApp(_ config: LaunchConfig = LaunchConfig(), waitForTabBar: Bool = true,
                   file: StaticString = #filePath, line: UInt = #line) -> XCUIApplication {
        let app = XCUIApplication()
        config.apply(to: app)
        app.launch()
        if waitForTabBar {
            XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 20),
                          "Tab bar did not appear within 20s", file: file, line: line)
        }
        return app
    }

    /// Attach a full-screen screenshot that survives in the .xcresult (exported by scripts/ui-test-device.sh).
    func snap(_ app: XCUIApplication, _ name: String) {
        let shot = app.screenshot()
        let att = XCTAttachment(screenshot: shot)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }

    /// Attach arbitrary text (findings, dumps) to the result bundle.
    func attachText(_ text: String, name: String) {
        let att = XCTAttachment(string: text)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }

    /// Scroll a scroll view until the element exists and is hittable (max `maxSwipes`).
    @discardableResult
    func scrollTo(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 8) -> Bool {
        var n = 0
        while n < maxSwipes {
            if element.exists && element.isHittable { return true }
            app.swipeUp(velocity: .slow)
            n += 1
        }
        return element.exists && element.isHittable
    }

    /// Tap a tab bar item by its label.
    func tapTab(_ app: XCUIApplication, _ label: String,
                file: StaticString = #filePath, line: UInt = #line) {
        let btn = app.tabBars.buttons[label]
        XCTAssertTrue(btn.waitForExistence(timeout: 5), "Tab '\(label)' missing", file: file, line: line)
        btn.tap()
    }

    /// Collect the visible labels of every static text and button on screen.
    func visibleLabels(_ app: XCUIApplication) -> [String] {
        var out: [String] = []
        for q in [app.staticTexts, app.buttons, app.navigationBars.staticTexts] {
            for el in q.allElementsBoundByIndex where el.exists {
                let label = el.label.trimmingCharacters(in: .whitespacesAndNewlines)
                if !label.isEmpty { out.append(label) }
            }
        }
        return Array(Set(out)).sorted()
    }
}

extension String {
    /// True when the string contains hiragana, katakana, or CJK ideographs.
    var containsJapanese: Bool {
        unicodeScalars.contains { s in
            (0x3040...0x30FF).contains(s.value) || (0x4E00...0x9FFF).contains(s.value)
        }
    }
}

// MARK: - Pixel sampling (design checks)

extension UIImage {
    /// Relative luminance (0 = black, 1 = white) of the pixel at `point` in *points*.
    func luminance(at point: CGPoint) -> CGFloat? {
        guard let cg = cgImage else { return nil }
        let px = Int(point.x * scale), py = Int(point.y * scale)
        guard px >= 0, py >= 0, px < cg.width, py < cg.height else { return nil }
        var rgba = [UInt8](repeating: 0, count: 4)
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: &rgba, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                  space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.draw(cg, in: CGRect(x: -px, y: -(cg.height - 1 - py), width: cg.width, height: cg.height))
        let r = CGFloat(rgba[0]) / 255, g = CGFloat(rgba[1]) / 255, b = CGFloat(rgba[2]) / 255
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
}
