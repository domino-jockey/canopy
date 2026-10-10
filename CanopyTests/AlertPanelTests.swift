import AppKit
import Testing
@testable import Canopy

@MainActor
struct AlertPanelTests {
    /// The pill must measure its full text, or the window cuts it off.
    @Test func pillMeasuresItsText() {
        let model = AlertModel()
        model.minutesWithoutBreak = 45
        let panel = AlertPanel(clickThrough: false, content: OvertimeAlert(model: model) {})
        let size = panel.fittingSize
        #expect(size.width > 150 && size.height > 40, "\(size)")
    }

    /// Wider text, wider pill (measured fresh each time, not stuck at the first size).
    @Test func pillGrowsWithText() {
        let model = AlertModel()
        model.minutesWithoutBreak = 1
        let panel = AlertPanel(clickThrough: false, content: OvertimeAlert(model: model) {})
        let before = panel.fittingSize.width
        model.minutesWithoutBreak = 12345
        #expect(panel.fittingSize.width > before)
    }

    @Test func notificationTexts() {
        let model = AlertModel()
        model.secondsToBreak = 30
        #expect(AlertNotifier.text(for: .headsUp, model: model).title == "Short break in 30 seconds")
        model.minutesWithoutBreak = 45
        #expect(AlertNotifier.text(for: .overtime, model: model).title == "45 minutes without a break")
        model.smartPause = .meeting
        #expect(AlertNotifier.text(for: .smartPause, model: model).title == "Paused for your call")
    }

    @Test func notificationSettingSurvivesSaveAndLoad() {
        let defaults = FakeClock.cleanDefaults()
        var settings = TimerSettings()
        settings.alertsAsNotifications = true
        settings.save(to: defaults)
        #expect(TimerSettings.load(from: defaults) == settings)
    }
}
