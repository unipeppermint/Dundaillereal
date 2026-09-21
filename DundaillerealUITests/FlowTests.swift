import XCTest

final class FlowTests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["--ui-testing", UUID().uuidString]
        app.launch()
    }

    func tap(_ element: XCUIElement) {
        guard element.waitForExistence(timeout: 5) else {
            XCTFail("Element did not appear: \(element)")
            return
        }
        for _ in 0..<14 {
            let scroll = app.scrollViews.firstMatch
            let safeTop = scroll.frame.minY + 32
            if element.elementType == .textField && element.exists && element.frame.midY < safeTop {
                scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)).press(
                    forDuration: 0.05,
                    thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6)))
                continue
            }
            if element.isHittable {
                element.tap()
                return
            }
            if element.exists && element.frame.maxY < safeTop {
                app.swipeDown()
            } else {
                scroll.swipeUp()
            }
        }
        XCTFail("Cannot tap \(element)")
    }

    func capture(_ name: String) {
        let item = XCTAttachment(screenshot: app.screenshot())
        item.name = name
        item.lifetime = .keepAlways
        add(item)
    }

    func top() { for _ in 0..<5 { app.swipeDown() } }

    func testFormalResumeAndFinish() {
        capture("visual-home")
        tap(app.buttons["开始游戏  →"].firstMatch)
        capture("visual-detail")
        tap(app.buttons["开始游戏"])
        tap(app.buttons["开局"])
        for target in [6, 8, 10, 12, 14, 16] {
            tap(app.buttons["投出骰子"])
            if target == 8 {
                XCTAssertTrue(app.buttons["station-6"].waitForExistence(timeout: 5))
                XCTAssertTrue((app.buttons["station-6"].value as? String)?.hasPrefix("已填写，") == true)
                capture("scored-route-node")
            }
            if target == 6 {
                capture("visual-board")
                let value = app.buttons["die-0"].label
                app.terminate()
                app.launch()
                tap(
                    app.buttons.matching(NSPredicate(format: "label BEGINSWITH '继续上局' ")).firstMatch
                )
                XCTAssertEqual(app.buttons["die-0"].label, value)
            }
            tap(app.buttons["die-0"])
            tap(app.buttons["station-\(target)"])
            tap(app.buttons["确认到站"])
            tap(app.buttons[target == 16 ? "查看结算" : "传给下一位玩家"])
        }
        XCTAssertTrue(app.staticTexts["这一局，值得珍藏"].waitForExistence(timeout: 3))
        tap(app.buttons["回到游戏桌"])
        tap(app.tabBars.buttons["收藏柜"])
        XCTAssertTrue(app.staticTexts["对局记录 · 1"].exists)
    }

    func testRerollKeepsOtherDice() {
        tap(app.buttons["开始游戏  →"].firstMatch)
        tap(app.buttons["开始游戏"])
        tap(app.buttons["开局"])
        tap(app.buttons["投出骰子"])
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.otherElements["dice-roll-presentation"])
        waitForExpectations(timeout: 3)
        let first = app.buttons["die-0"].label
        let third = app.buttons["die-2"].label
        tap(app.buttons.matching(NSPredicate(format: "label BEGINSWITH '重掷一颗'")).firstMatch)
        tap(app.buttons.matching(NSPredicate(format: "label BEGINSWITH '第 2 颗'")).firstMatch)
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.otherElements["dice-roll-presentation"])
        waitForExpectations(timeout: 3)
        XCTAssertEqual(app.buttons["die-0"].label, first)
        XCTAssertEqual(app.buttons["die-2"].label, third)
        XCTAssertTrue(app.staticTexts["本局剩余重掷 1 次 · 连续精准 0 次"].exists)
        capture("dice-depth-after-reroll")
    }

    func testEditorTrialAndLibrary() {
        tap(app.tabBars.buttons["工坊"])
        tap(app.buttons["＋ 从《恰好到站》新建"])
        capture("visual-editor")
        tap(app.buttons["结束条件"])
        let rounds = app.textFields["每人轮数（1～12）"]
        tap(rounds)
        rounds.tap()
        rounds.typeText(XCUIKeyboardKey.delete.rawValue + "1")
        let targets = app.textFields["目标站点（逗号分隔，与轮数一致）"]
        tap(targets)
        if app.buttons["完成输入"].exists { targets.tap() }
        let existing = targets.value as? String ?? ""
        targets.typeText(
            String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count) + "6")
        tap(app.buttons["完成输入"])
        tap(app.buttons["保存作品"])
        tap(app.alerts.buttons["知道了"])
        tap(app.buttons["试玩这套规则"])
        tap(app.buttons["投出骰子"])
        tap(app.buttons["die-0"])
        tap(app.buttons["station-6"])
        tap(app.buttons["确认到站"])
        tap(app.buttons["查看结算"])
        XCTAssertTrue(app.staticTexts["试玩完成"].exists)
        tap(app.buttons["回到游戏桌"])
        XCTAssertTrue(app.staticTexts["我的作品 · 1"].exists)
    }
}
