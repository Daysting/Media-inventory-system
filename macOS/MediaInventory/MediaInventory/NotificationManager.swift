import Cocoa

class NotificationManager {
    func requestUserPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    NSApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func sendCheckoutReminder(media: String, dueDate: Date) {
        let notification = NSUserNotification()
        notification.title = "Media Checkout Reminder"
        notification.subtitle = media
        notification.informativeText = "Due back on \(dateFormatter.string(from: dueDate))"
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    func sendOverdueAlert(media: String, borrower: String, daysOverdue: Int) {
        let notification = NSUserNotification()
        notification.title = "Overdue Media Alert"
        notification.subtitle = "\(media) - \(daysOverdue) days overdue"
        notification.informativeText = "Please contact \(borrower) to return this item"
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    func sendSuccessNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}
