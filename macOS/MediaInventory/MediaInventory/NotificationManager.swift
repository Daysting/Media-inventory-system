import Cocoa
import UserNotifications

class NotificationManager {
    func requestUserPermission() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { granted, error in
                    if let nsError = error as NSError? {
                        if nsError.domain == UNErrorDomain,
                           nsError.code == UNError.notificationsNotAllowed.rawValue {
                            print("Notifications are disabled for this app in System Settings.")
                            return
                        }
                        print("Notification permission error: \(nsError.localizedDescription)")
                        return
                    }

                    if !granted {
                        print("Notification permission was not granted")
                    }
                }
            case .denied:
                print("Notifications are disabled for this app in System Settings.")
            case .authorized, .provisional, .ephemeral:
                break
            @unknown default:
                break
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
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                return
            }

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
