import XCTest

final class FlowTests: XCTestCase {
    let app = XCUIApplication()
    override func setUpWithError() throws { continueAfterFailure = false; app.launchArguments = ["--ui-testing", UUID().uuidString]; app.launch() }
    func tap(_ element: XCUIElement) {
        for _ in 0..<9 { if element.isHittable { element.tap(); return }; if element.exists && element.frame.maxY < 180 { app.swipeDown() } else { app.scrollViews.firstMatch.swipeUp() } }
        XCTFail("Cannot tap \(element)")
    }
    func top() { for _ in 0..<5 { app.swipeDown() } }
    func testFormalResumeAndFinish() {
        tap(app.buttons["开始游戏  →"].firstMatch); tap(app.buttons["开始游戏"]); tap(app.buttons["开局"])
        for target in [6,8,10,12,14,16] {
            tap(app.buttons["投出骰子"])
            if target == 6 {
                let value = app.buttons["die-0"].label
                app.terminate(); app.launch(); tap(app.buttons.matching(NSPredicate(format: "label BEGINSWITH '继续上局' ")).firstMatch)
                XCTAssertEqual(app.buttons["die-0"].label, value)
            }
            tap(app.buttons["die-0"]); tap(app.buttons["station-\(target)"]); tap(app.buttons["确认到站"])
            tap(app.buttons[target == 16 ? "查看结算" : "传给下一位玩家"])
        }
        XCTAssertTrue(app.staticTexts["这一局，值得珍藏"].waitForExistence(timeout: 3))
        tap(app.buttons["回到游戏桌"]); tap(app.tabBars.buttons["收藏柜"])
        XCTAssertTrue(app.staticTexts["对局记录 · 1"].exists)
    }
    func testEditorTrialAndLibrary() {
        tap(app.tabBars.buttons["工坊"]); tap(app.buttons["＋ 从《恰好到站》新建"])
        let rounds = app.textFields["每人轮数（1～12）"]; tap(rounds)
        // Replace using select-all keyboard shortcut supported by simulator hardware keyboard.
        rounds.tap(); rounds.typeText(XCUIKeyboardKey.delete.rawValue + "1")
        let targets = app.textFields["目标站点（逗号分隔，与轮数一致）"]; tap(targets)
        let existing = targets.value as? String ?? ""; targets.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count) + "6")
        tap(app.buttons["完成输入"]); tap(app.buttons["保存作品"]); tap(app.alerts.buttons["知道了"])
        tap(app.buttons["试玩这套规则"]); tap(app.buttons["投出骰子"]); tap(app.buttons["die-0"]); tap(app.buttons["station-6"]); tap(app.buttons["确认到站"]); tap(app.buttons["查看结算"])
        XCTAssertTrue(app.staticTexts["试玩完成"].exists)
        tap(app.buttons["回到游戏桌"]); XCTAssertTrue(app.staticTexts["我的作品 · 1"].exists)
    }
}
