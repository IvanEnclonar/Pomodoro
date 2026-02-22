import XCTest
@testable import Pomodoro

final class TimerManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset user defaults for testing
        let domain = Bundle.main.bundleIdentifier ?? "Pomodoro"
        UserDefaults.standard.removePersistentDomain(forName: domain)
    }

    func testDefaultValues() {
        let manager = TimerManager()
        XCTAssertEqual(manager.focusDurationMinutes, 25)
        XCTAssertEqual(manager.shortBreakDurationMinutes, 5)
        XCTAssertEqual(manager.longBreakDurationMinutes, 15)
    }

    func testInvalidFocusDuration() {
        // Set an invalid value
        UserDefaults.standard.set(-10, forKey: "focusDurationMinutes")

        let manager = TimerManager()

        // Should be clamped to min (e.g. 5 or 1)
        XCTAssertGreaterThanOrEqual(manager.focusDurationMinutes, 5)
    }

    func testExcessiveFocusDuration() {
        // Set an excessive value
        UserDefaults.standard.set(1000, forKey: "focusDurationMinutes")

        let manager = TimerManager()

        // Should be clamped to max (e.g. 240)
        XCTAssertLessThanOrEqual(manager.focusDurationMinutes, 240)
    }
}
