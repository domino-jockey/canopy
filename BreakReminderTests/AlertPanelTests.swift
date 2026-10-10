import AppKit
import Testing
@testable import BreakReminder

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
}
