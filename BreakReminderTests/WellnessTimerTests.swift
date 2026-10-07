import AppKit
import Testing
@testable import BreakReminder

struct WellnessTimerTests {
    private func settings(posture: Bool = true, blink: Bool = true) -> TimerSettings {
        var settings = TimerSettings()
        settings.posture.enabled = posture
        settings.blink.enabled = blink
        return settings
    }

    /// Advances one second at a time; returns each reminder shown and the second it showed.
    private func run(_ timer: inout WellnessTimer, seconds: Int, settings: TimerSettings) -> [(Int, WellnessKind)] {
        (1...seconds).compactMap { second in timer.advance(by: 1, settings: settings).map { (second, $0) } }
    }

    @Test func remindersOffByDefault() {
        var timer = WellnessTimer()
        #expect(run(&timer, seconds: 3600, settings: TimerSettings()).isEmpty)
    }

    @Test func blinkEveryFiveMinutesPostureEveryTen() {
        var timer = WellnessTimer()
        let shown = run(&timer, seconds: 20 * 60, settings: settings())
        #expect(shown.map(\.0) == [300, 600, 900, 1200])
        // At 10 and 20 minutes both are due: posture shows, blink starts over.
        #expect(shown.map(\.1) == [.blink, .posture, .blink, .posture])
    }

    @Test func onlyEnabledReminderShows() {
        var timer = WellnessTimer()
        let shown = run(&timer, seconds: 10 * 60, settings: settings(blink: false))
        #expect(shown.map(\.1) == [.posture])
    }

    @Test func resetStartsCountdownsOver() {
        var timer = WellnessTimer()
        _ = run(&timer, seconds: 299, settings: settings())
        timer.reset()
        #expect(run(&timer, seconds: 299, settings: settings()).isEmpty)
    }

    @MainActor @Test func wellnessSettingsSurviveSaveAndLoad() {
        let defaults = FakeClock.cleanDefaults()
        var settings = TimerSettings()
        settings.posture = WellnessReminder(enabled: true, interval: 900, style: .flash, size: .small,
                                            position: GridPosition(row: 0, column: 2))
        settings.dimForReminders = false
        settings.save(to: defaults)
        #expect(TimerSettings.load(from: defaults) == settings)
    }
}

@MainActor
struct SoundSettingsTests {
    @Test func everySoundLoads() {
        for name in ["gong_start", "gong_end", "blip_start"] {
            #expect(NSSound(named: name) != nil, "\(name)")
        }
    }

    @Test func soundSettingsSurviveSaveAndLoad() {
        let defaults = FakeClock.cleanDefaults()
        var settings = TimerSettings()
        settings.breakSounds = false
        settings.soundVolume = 0.25
        settings.save(to: defaults)
        #expect(TimerSettings.load(from: defaults) == settings)
    }
}
