import Testing
@testable import BreakReminder

struct TimeFormatTests {
    @Test(arguments: [
        (0.0, "0:00"),
        (-3.0, "0:00"),
        (0.4, "0:00"),
        (18.97, "0:19"),
        (19.03, "0:19"),
        (59.2, "0:59"),
        (65.0, "1:05"),
        (20.0 * 60, "20:00"),
        (75.0 * 60, "75:00"),
    ])
    func clock(seconds: Double, expected: String) {
        #expect(TimeFormat.clock(seconds) == expected)
    }

    @Test(arguments: [
        (0.0, "0m"),
        (0.4, "0m"),
        (1.0, "1m"),
        (60.0, "1m"),
        (60.2, "1m"),
        (61.0, "2m"),
        (20.0 * 60, "20m"),
    ])
    func minutes(seconds: Double, expected: String) {
        #expect(TimeFormat.minutes(seconds) == expected)
    }
}
