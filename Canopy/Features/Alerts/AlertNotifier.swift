import UserNotifications

/// Shows alerts as normal macOS notifications instead of pills (Settings › Alerts › Show alerts as).
/// The heads-up gets Start and Snooze buttons.
@MainActor
final class AlertNotifier: NSObject, UNUserNotificationCenterDelegate {
    private let scheduler: BreakScheduler
    private let center = UNUserNotificationCenter.current()
    private var askedPermission = false

    private static let snoozeMinutes = [1, 5, 15]

    init(scheduler: BreakScheduler) {
        self.scheduler = scheduler
        super.init()
        center.delegate = self
        let start = UNNotificationAction(identifier: "start", title: "Start Break Now")
        let snoozes = Self.snoozeMinutes.map { UNNotificationAction(identifier: "snooze\($0)", title: "Snooze \($0) min") }
        center.setNotificationCategories([
            UNNotificationCategory(identifier: "headsUp", actions: [start] + snoozes, intentIdentifiers: []),
            UNNotificationCategory(identifier: "headsUpNoSnooze", actions: [start], intentIdentifiers: []),
        ])
    }

    func post(_ kind: AlertKind, model: AlertModel) {
        if !askedPermission {
            askedPermission = true
            center.requestAuthorization(options: [.alert]) { _, _ in }
        }
        let text = Self.text(for: kind, model: model)
        let content = UNMutableNotificationContent()
        content.title = text.title
        content.body = text.body
        // The app plays its own reminder sound.
        if kind == .headsUp { content.categoryIdentifier = model.canSnooze ? "headsUp" : "headsUpNoSnooze" }
        center.add(UNNotificationRequest(identifier: "\(kind)", content: content, trigger: nil))
    }

    func remove(_ kind: AlertKind) {
        center.removeDeliveredNotifications(withIdentifiers: ["\(kind)"])
    }

    static func text(for kind: AlertKind, model: AlertModel) -> (title: String, body: String) {
        let breakName = model.breakKind == .long ? "Long break" : "Short break"
        return switch kind {
        case .headsUp, .countdown:
            ("\(breakName) in \(Int(model.secondsToBreak.rounded())) seconds",
             model.breakKind == .long ? "A long break is coming. Time to stretch." : "Almost time. Your eyes will appreciate this.")
        case .overtime:
            ("\(model.minutesWithoutBreak) \(model.minutesWithoutBreak == 1 ? "minute" : "minutes") without a break", "Time to rest your eyes.")
        case .smartPause:
            (SmartPauseAlert.title(for: model.smartPause), "")
        case .welcomeBack:
            ("Welcome back", "That counted as a break. Next one in \(TimeFormat.clock(model.secondsToBreak)).")
        }
    }

    // Shows the banner even while the app is in front (Settings open).
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        let action = response.actionIdentifier
        await MainActor.run {
            if action == "start" {
                scheduler.startBreakNow()
            } else if action.hasPrefix("snooze"), let minutes = Int(action.dropFirst("snooze".count)) {
                scheduler.snooze(minutes: minutes)
            }
        }
    }
}
