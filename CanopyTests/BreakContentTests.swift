import AppKit
import Testing
@testable import Canopy

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

    @Test func turnedOffMessagesAreLeftOut() {
        var settings = TimerSettings()
        settings.showExercises = false
        settings.disabledExercises = ["Blink it out"]
        #expect(BreakMessages.pool(for: .short, settings: settings) == BreakMessages.short.filter { $0.title != "Blink it out" })
    }

    @Test func everythingOffStillHasSomethingToSay() {
        var settings = TimerSettings()
        settings.showExercises = false
        settings.disabledExercises = Set(BreakMessages.long.map(\.title))
        #expect(BreakMessages.pool(for: .long, settings: settings) == BreakMessages.long)
    }

    @Test func ownMessagesAreMixedInForTheirKindOfBreak() {
        var settings = TimerSettings()
        settings.customShortMessages = [BreakMessage(title: "Wall push-ups", subtitle: "Ten against the wall"),
                                        BreakMessage(title: "", subtitle: "")]
        settings.customLongMessages = [BreakMessage(title: "Make tea", subtitle: "")]
        let short = BreakMessages.pool(for: .short, settings: settings)
        #expect(short.last == BreakMessage(title: "Wall push-ups", subtitle: "Ten against the wall"))
        #expect(short.count == BreakMessages.shortExercises.count + 1) // the empty one is ignored
        let long = BreakMessages.pool(for: .long, settings: settings)
        #expect(long == BreakMessages.longExercises + [BreakMessage(title: "Make tea", subtitle: "")])
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
        settings.disabledExercises = ["Palming"]
        settings.customShortMessages = [BreakMessage(title: "Hi", subtitle: "There")]
        settings.customLongMessages = [BreakMessage(title: "Bye", subtitle: "")]
        settings.save(to: defaults)
        #expect(TimerSettings.load(from: defaults) == settings)
    }

    /// Older versions saved own messages as plain titles, in one list for both kinds of break.
    @Test func oldTitlesGoToBothLists() {
        let defaults = FakeClock.cleanDefaults()
        defaults.set(Data(#"{"customMessages":["Drink some water"]}"#.utf8), forKey: "timerSettings")
        let settings = TimerSettings.load(from: defaults)
        #expect(settings.customShortMessages == [BreakMessage(title: "Drink some water", subtitle: "")])
        #expect(settings.customLongMessages == [BreakMessage(title: "Drink some water", subtitle: "")])
    }

    @Test func oldMessageListGoesToBothLists() {
        let defaults = FakeClock.cleanDefaults()
        defaults.set(Data(#"{"customMessages":[{"title":"Hi","subtitle":"There"}]}"#.utf8), forKey: "timerSettings")
        let settings = TimerSettings.load(from: defaults)
        #expect(settings.customShortMessages == [BreakMessage(title: "Hi", subtitle: "There")])
        #expect(settings.customLongMessages == [BreakMessage(title: "Hi", subtitle: "There")])
    }
}
