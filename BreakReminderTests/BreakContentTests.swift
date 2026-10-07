import AppKit
import Testing
@testable import BreakReminder

@MainActor
struct BreakContentTests {
    @Test func exercisesByDefault() {
        let settings = TimerSettings()
        #expect(BreakMessages.pool(for: .short, settings: settings) == BreakMessages.shortExercises)
        #expect(BreakMessages.pool(for: .long, settings: settings) == BreakMessages.longExercises)
    }

    @Test func plainMessagesWhenExercisesOff() {
        var settings = TimerSettings()
        settings.showExercises = false
        #expect(BreakMessages.pool(for: .short, settings: settings) == BreakMessages.short)
    }

    @Test func turnedOffExercisesAreLeftOut() {
        var settings = TimerSettings()
        settings.disabledExercises = ["Palming"]
        #expect(!BreakMessages.pool(for: .short, settings: settings).contains { $0.title == "Palming" })
    }

    @Test func allExercisesOffFallsBackToMessages() {
        var settings = TimerSettings()
        settings.disabledExercises = Set(BreakMessages.longExercises.map(\.title))
        #expect(BreakMessages.pool(for: .long, settings: settings) == BreakMessages.long)
    }

    @Test func ownMessagesAreMixedIn() {
        var settings = TimerSettings()
        settings.customMessages = ["Drink some water", ""]
        let pool = BreakMessages.pool(for: .short, settings: settings)
        #expect(pool.last == BreakMessage(title: "Drink some water", subtitle: ""))
        #expect(pool.count == BreakMessages.shortExercises.count + 1) // the empty one is ignored
    }

    @Test func everyExerciseSymbolExists() {
        for exercise in BreakMessages.allExercises {
            #expect(NSImage(systemSymbolName: exercise.symbol!, accessibilityDescription: nil) != nil, "\(exercise.title)")
        }
    }

    @Test func breakScreenSettingsSurviveSaveAndLoad() {
        let defaults = FakeClock.cleanDefaults()
        var settings = TimerSettings()
        settings.breakBackground = .image
        settings.backgroundImagePath = "/tmp/x.jpg"
        settings.showClockOnBreak = false
        settings.disabledExercises = ["Palming"]
        settings.customMessages = ["Hi"]
        settings.save(to: defaults)
        #expect(TimerSettings.load(from: defaults) == settings)
    }
}
