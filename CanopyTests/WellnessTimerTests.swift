import AppKit
import Testing
@testable import Canopy

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

    @Test func reminderDueSoonShowsWithTheOther() {
        var timer = WellnessTimer()
        _ = run(&timer, seconds: 30, settings: settings(posture: false))
        // Blink is now 30 s ahead of posture. Blink's second flash (570 s) is 30 s before posture's,
        // so posture counts as shown with it instead of flashing again at 600 s.
        let shown = run(&timer, seconds: 10 * 60, settings: settings())
        #expect(shown.map(\.1) == [.blink, .blink])
        #expect(shown.map(\.0) == [270, 570])
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
        settings.posture = WellnessReminder(enabled: true, interval: 900)
        settings.remindersDuringSmartPause = true
        settings.save(to: defaults)
        #expect(TimerSettings.load(from: defaults) == settings)
    }

    /// Settings saved before the bubble style was removed still load.
    @MainActor @Test func oldBubbleSettingsStillLoad() {
        let defaults = FakeClock.cleanDefaults()
        let old = #"{"posture":{"enabled":true,"interval":900,"style":"bubble","size":"large","position":{"row":1,"column":1}},"dimForReminders":true}"#
        defaults.set(Data(old.utf8), forKey: "timerSettings")
        #expect(TimerSettings.load(from: defaults).posture == WellnessReminder(enabled: true, interval: 900))
    }
}

@MainActor
struct SoundSettingsTests {
    @Test func everySoundLoads() {
        for choice in SoundChoice.allCases {
            for end in [false, true] {
                #expect(NSSound(named: choice.fileName(end: end)) != nil, "\(choice.fileName(end: end))")
            }
        }
    }

    @Test func soundSettingsSurviveSaveAndLoad() {
        let defaults = FakeClock.cleanDefaults()
        var settings = TimerSettings()
        settings.breakSounds = false
        settings.soundVolume = 0.25
        settings.breakStartSound = .windChime
        settings.breakEndSound = .ping
        settings.reminderSound = .ticToc
        settings.alertSounds = false
        settings.alertSound = .crystalGlass
        settings.save(to: defaults)
        #expect(TimerSettings.load(from: defaults) == settings)
    }

    /// Older versions had one sound for reminders and alerts. Alerts keep what it was.
    @Test func alertSoundComesFromOldReminderSound() throws {
        var settings = TimerSettings()
        settings.reminderSounds = false
        settings.reminderSound = .gong
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(settings)) as! [String: Any]
        json["alertSounds"] = nil
        json["alertSound"] = nil
        let loaded = try JSONDecoder().decode(TimerSettings.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(loaded.alertSounds == false)
        #expect(loaded.alertSound == .gong)
    }
}
