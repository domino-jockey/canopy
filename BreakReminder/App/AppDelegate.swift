import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let scheduler = BreakScheduler()
    private var statusItem: StatusItemController?
    private var breakOverlay: BreakOverlayController?
    private var settingsWindow: SettingsWindowController?
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settingsWindow = SettingsWindowController(scheduler: scheduler)
        self.settingsWindow = settingsWindow
        statusItem = StatusItemController(scheduler: scheduler, openSettings: settingsWindow.show)
        breakOverlay = BreakOverlayController(scheduler: scheduler)
        scheduler.start()
        tick()

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        timer.tolerance = 0.1
        // .common keeps the timer running while a menu is open.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        let anyInput = CGEventType(rawValue: ~0)!
        let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
        scheduler.tick(now: .now, idleSeconds: idle)
        statusItem?.refreshWidth()
    }
}
