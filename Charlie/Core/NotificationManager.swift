import UserNotifications
import Foundation

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private init() {}

    // Request permission — called on first launch
    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        guard settings.authorizationStatus != .authorized else {
            isAuthorized = true
            return
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
    }

    // Schedule a trip reminder — fires 3 days before trip start
    func scheduleTripReminder(for context: Context) {
        guard isAuthorized else { return }
        guard let datesString = context.dates else { return }

        // Try to extract a start date from dates string (simple heuristic)
        // For now, schedule 3 days from now as a placeholder trigger
        let center = UNUserNotificationCenter.current()

        // Remove any existing reminder for this context
        center.removePendingNotificationRequests(withIdentifiers: ["trip-reminder-\(context.key)"])

        let content = UNMutableNotificationContent()
        content.title = "\(context.emoji) \(context.label) is coming up!"
        content.body = "Your trip is in 3 days. Check your saved places and finalize your list."
        content.sound = .default
        content.userInfo = ["contextKey": context.key, "type": "trip-reminder"]

        // Trigger 3 days from now at 9am (placeholder — real impl parses trip dates)
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date().addingTimeInterval(3 * 86400))
        components.hour = 9
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "trip-reminder-\(context.key)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error { print("[NotificationManager] Failed to schedule trip reminder: \(error)") }
        }
    }

    // Schedule daily morning briefing at 7am (only when a trip is active)
    func scheduleMorningBriefing(contextLabel: String, contextEmoji: String, savedCount: Int, unreviewedCount: Int) {
        guard isAuthorized else { return }
        let center = UNUserNotificationCenter.current()

        center.removePendingNotificationRequests(withIdentifiers: ["morning-briefing"])

        let content = UNMutableNotificationContent()
        content.title = "\(contextEmoji) Charlie Morning Brief"
        content.body = "\(savedCount) saved, \(unreviewedCount) to review for your \(contextLabel)."
        content.sound = .default
        content.badge = NSNumber(value: unreviewedCount)
        content.userInfo = ["type": "morning-briefing"]

        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "morning-briefing",
            content: content,
            trigger: trigger
        )
        center.add(request) { error in
            if let error { print("[NotificationManager] Failed to schedule morning briefing: \(error)") }
        }
    }

    // Cancel all Charlie notifications (called when no active context)
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    // Update badge count (unreviewd discoveries)
    func updateBadge(count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count
    }
}