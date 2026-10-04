import Testing
@testable import Glance

struct TimeFormatTests {
    @Test(arguments: [
        (0.0, "0:00"),
        (-3.0, "0:00"),
        (0.4, "0:01"),
        (59.2, "1:00"),
        (65.0, "1:05"),
        (20.0 * 60, "20:00"),
        (75.0 * 60, "75:00"),
    ])
    func clock(seconds: Double, expected: String) {
        #expect(TimeFormat.clock(seconds) == expected)
    }
}
