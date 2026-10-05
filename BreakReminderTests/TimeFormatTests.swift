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
}
