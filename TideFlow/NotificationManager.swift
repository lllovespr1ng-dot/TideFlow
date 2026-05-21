import UserNotifications
import EventKit
import Combine

// NSObject is required to adopt UNUserNotificationCenterDelegate.
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {

    override init() {
        super.init()
        // Make this object the delegate so notifications display as banners
        // even when the app is in the foreground.
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Show alert + play sound for notifications that arrive while the app is open.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Permission

    func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Calendar event reminders

    /// Cancels all TideFlow calendar-event notifications, then schedules
    /// 1-hour-before + at-start reminders for every event in the list.
    /// Everything happens inside the getPending callback to avoid the race
    /// condition where removal runs AFTER the new requests are added.
    func scheduleReminders(
        for events: [EKEvent],
        oneHourBody: String = "Starting in 1 hour",
        nowBody: String     = "Starting now"
    ) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { existing in
            let staleIDs = existing
                .map(\.identifier)
                .filter { $0.hasPrefix("tf-event-") }
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: staleIDs)

            for event in events {
                self.scheduleEventNudges(event, oneHourBody: oneHourBody, nowBody: nowBody)
            }
        }
    }

    private func scheduleEventNudges(
        _ event: EKEvent,
        oneHourBody: String,
        nowBody: String
    ) {
        guard let id = event.eventIdentifier else { return }
        let title     = event.title ?? "Event"
        let startDate: Date = event.startDate  // EKEvent.startDate is Date! — force-unwrap is safe

        let nudges: [(offsetMinutes: Int, body: String)] = [
            (60, oneHourBody),
            (0,  nowBody),
        ]

        for nudge in nudges {
            let fireDate = startDate.addingTimeInterval(Double(-nudge.offsetMinutes * 60))
            guard fireDate > Date() else { continue }

            let content   = UNMutableNotificationContent()
            content.title = title
            content.body  = nudge.body
            content.sound = .default

            let comps   = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: "tf-event-\(id)-\(nudge.offsetMinutes)",
                content:    content,
                trigger:    trigger)

            UNUserNotificationCenter.current().add(request) { err in
                if let err { print("⚠️ Notification error: \(err)") }
            }
        }
    }

    // MARK: - Focus session timer notifications

    private let focusNotifID = "tf-focus-session"

    /// Schedules a "session complete" notification `seconds` from now.
    /// Call this when a focus session starts.
    func scheduleFocusEnd(taskTitle: String, body: String, in seconds: TimeInterval) {
        // Remove any leftover from a previous session first
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [focusNotifID])

        let content   = UNMutableNotificationContent()
        content.title = taskTitle
        content.body  = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(
            identifier: focusNotifID, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { err in
            if let err { print("⚠️ Focus notification error: \(err)") }
        }
    }

    /// Cancels a pending focus-end notification (call on early exit or natural completion).
    func cancelFocusNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [focusNotifID])
    }
}
