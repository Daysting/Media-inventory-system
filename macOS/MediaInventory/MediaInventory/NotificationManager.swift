import Cocoa
import UserNotifications

class NotificationManager {
    /// Request notification permission only when there is something to actually send.
    /// Do NOT call this eagerly on app launch — doing so triggers an IPC round-trip to
    /// usernoted even when the user has denied notifications, which produces annoying
    /// kernel-level port errors in the console.
    private func requestPermissionIfNeeded(then completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion(true)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    completion(granted)
                }
            case .denied:
                completion(false)
            @unknown default:
                completion(false)
            }
        }
    }
    
    func sendCheckoutReminder(media: String, dueDate: Date) {
        scheduleNotification(
            title: "Media Checkout Reminder",
            subtitle: media,
            body: "Due back on \(dateFormatter.string(from: dueDate))"
        )
    }
    
    func sendOverdueAlert(media: String, borrower: String, daysOverdue: Int) {
        scheduleNotification(
            title: "Overdue Media Alert",
            subtitle: "\(media) - \(daysOverdue) days overdue",
            body: "Please contact \(borrower) to return this item"
        )
    }
    
    func sendSuccessNotification(title: String, message: String) {
        scheduleNotification(
            title: title,
            subtitle: "",
            body: message
        )
    }

    private func scheduleNotification(title: String, subtitle: String, body: String) {
        requestPermissionIfNeeded { granted in
            guard granted else { return }

            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = title
            content.subtitle = subtitle
            content.body = body
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )

            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}
