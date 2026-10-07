import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let scheduler = BreakScheduler()
    private var statusItem: StatusItemController?
    private var breakOverlay: BreakOverlayController?
    private var alerts: AlertsController?
    private var settingsWindow: SettingsWindowController?
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let alerts = AlertsController(scheduler: scheduler)
        self.alerts = alerts
        let settingsWindow = SettingsWindowController(scheduler: scheduler, previewAlert: alerts.preview)
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

    /// ⌘Q would make the break screen vanish, so quitting is refused during a break.
    /// Logging out and shutting down ask via an Apple event, and still quit normally.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if scheduler.isOnBreak && NSAppleEventManager.shared().currentAppleEvent == nil {
            return .terminateCancel
        }
        return .terminateNow
    }

    /// `breakreminder://` links, opened by Shortcuts automations.
    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach { _ = SmartPauseMonitor.handle($0) }
        tick()
    }

    private func tick() {
        let anyInput = CGEventType(rawValue: ~0)!
        let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
        let typingIdle = [CGEventType.keyDown, .leftMouseDragged, .rightMouseDragged]
            .map { CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0) }
            .min()!
        scheduler.tick(now: .now, idleSeconds: idle, typingIdleSeconds: typingIdle,
                       smartPause: SmartPauseMonitor.reason(for: scheduler.settings))
        alerts?.update()
        statusItem?.refreshWidth()
    }
}
