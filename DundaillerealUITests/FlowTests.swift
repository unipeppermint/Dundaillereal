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
        tap(app.buttons["Start Game  →"].firstMatch)
        capture("visual-detail")
        tap(app.buttons["Start Game"])
        tap(app.buttons["Begin"])
        for target in [6, 8, 10, 12, 14, 16] {
            tap(app.buttons["Roll Dice"])
            if target == 8 {
                XCTAssertTrue(app.buttons["station-6"].waitForExistence(timeout: 5))
                XCTAssertTrue((app.buttons["station-6"].value as? String)?.hasPrefix("Scored, ") == true)
                capture("scored-route-node")
            }
            if target == 6 {
                capture("visual-board")
                let value = app.buttons["die-0"].label
                app.terminate()
                app.launch()
                tap(
                    app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Resume Game' ")).firstMatch
                )
                XCTAssertEqual(app.buttons["die-0"].label, value)
            }
            tap(app.buttons["die-0"])
            tap(app.buttons["station-\(target)"])
            tap(app.buttons["Confirm Stop"])
            tap(app.buttons[target == 16 ? "View Results" : "Next Turn"])
        }
        XCTAssertTrue(app.staticTexts["Game Complete"].waitForExistence(timeout: 3))
        tap(app.buttons["Back to Games"])
        tap(app.tabBars.buttons["Collection"])
        XCTAssertTrue(app.staticTexts["Game History · 1"].exists)
    }

    func testRerollKeepsOtherDice() {
        tap(app.buttons["Start Game  →"].firstMatch)
        tap(app.buttons["Start Game"])
        tap(app.buttons["Begin"])
        tap(app.buttons["Roll Dice"])
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.otherElements["dice-roll-presentation"])
        waitForExpectations(timeout: 3)
        let first = app.buttons["die-0"].label
        let third = app.buttons["die-2"].label
        tap(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Reroll One'")).firstMatch)
        tap(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Die 2'")).firstMatch)
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.otherElements["dice-roll-presentation"])
        waitForExpectations(timeout: 3)
        XCTAssertEqual(app.buttons["die-0"].label, first)
        XCTAssertEqual(app.buttons["die-2"].label, third)
        XCTAssertTrue(app.staticTexts["Rerolls left: 1 · Streak: 0"].exists)
        capture("dice-depth-after-reroll")
    }

    func testTemplatePresentation() {
        capture("english-home")
        for name in ["Lucky Pairs", "Bank or Bust"] {
            tap(app.buttons[name])
            capture("template-detail-" + name)
            tap(app.buttons["Customize"])
            XCTAssertTrue(app.buttons["Scoring"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["Streak Bonus"].exists)
            tap(app.buttons["Scoring"])
            if name == "Lucky Pairs" {
                XCTAssertTrue(app.textFields["Bonus per matching pair (0–10)"].exists)
            } else {
                XCTAssertTrue(app.staticTexts["Rolling the bust face scores zero for the round."].exists)
            }
            capture("template-editor-" + name)
            tap(app.buttons["Back"])
            tap(app.buttons["Back"])
        }
    }

    func testEditorTrialAndLibrary() {
        tap(app.tabBars.buttons["Workshop"])
        tap(app.buttons["+ Create from Right on Track"])
        capture("visual-editor")
        tap(app.buttons["Game Length"])
        let rounds = app.textFields["Rounds per player (1–12)"]
        tap(rounds)
        rounds.tap()
        rounds.typeText(XCUIKeyboardKey.delete.rawValue + "1")
        let targets = app.textFields["Target stops (comma-separated, one per round)"]
        tap(targets)
        if app.buttons["Done"].exists { targets.tap() }
        let existing = targets.value as? String ?? ""
        targets.typeText(
            String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count) + "6")
        tap(app.buttons["Done"])
        tap(app.buttons["Save Game"])
        tap(app.alerts.buttons["OK"])
        tap(app.buttons["Playtest Rules"])
        tap(app.buttons["Roll Dice"])
        tap(app.buttons["die-0"])
        tap(app.buttons["station-6"])
        tap(app.buttons["Confirm Stop"])
        tap(app.buttons["View Results"])
        XCTAssertTrue(app.staticTexts["Playtest Complete"].exists)
        tap(app.buttons["Back to Games"])
        XCTAssertTrue(app.staticTexts["My Games · 1"].exists)
    }
}
