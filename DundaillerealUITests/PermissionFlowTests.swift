import XCTest

/// Run on a fresh English- or Chinese-language simulator with no permission decisions.
final class PermissionFlowTests: XCTestCase {
    func testFirstLaunchRequestsTrackingBeforeNotifications() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let declineTracking = springboard.buttons.matching(NSPredicate(
            format: "label IN %@", ["Ask App Not to Track", "要求App不跟踪"])).firstMatch
        XCTAssertTrue(declineTracking.waitForExistence(timeout: 15), "ATT must be the first permission prompt")
        XCTAssertFalse(springboard.alerts.buttons.matching(NSPredicate(
            format: "label IN %@", ["Don’t Allow", "Don't Allow", "不允许"])).firstMatch.exists)
        let trackingScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        trackingScreenshot.name = "ATT-first-launch"
        trackingScreenshot.lifetime = .keepAlways
        add(trackingScreenshot)
        declineTracking.tap()

        let declineNotifications = springboard.alerts.buttons.matching(NSPredicate(
            format: "label IN %@", ["Don’t Allow", "Don't Allow", "不允许"])).firstMatch
        XCTAssertTrue(declineNotifications.waitForExistence(timeout: 10), "Notification permission must follow ATT even if tracking is declined")
        declineNotifications.tap()
        app.terminate()
        app.launch()
        XCTAssertFalse(declineTracking.waitForExistence(timeout: 3), "A stored tracking denial must not cause another prompt")
    }
}
