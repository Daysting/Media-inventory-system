import Cocoa
import SwiftUI

extension Notification.Name {
    static let backendStartupDiagnostic = Notification.Name("BackendStartupDiagnostic")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var notificationManager: NotificationManager?
    var searchIndexer: SearchIndexer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureApplicationIcon()
        emitDiagnostic("Local mode enabled: using native SQLite datastore")
        setupNotificationManager()
        if shouldEnableSpotlightIndexing() {
            setupSpotlightIntegration()
        } else {
            emitDiagnostic("Skipping Spotlight indexing in Debug build (toggle in Settings > Preferences)")
        }
    }

    private func configureApplicationIcon() {
        if let iconImage = NSImage(named: "AppIcon") {
            NSApp.applicationIconImage = iconImage
        }
    }

    // MARK: - Notifications
    // NotificationManager is instantiated here but permission is NOT requested eagerly.
    // The manager will request permission the first time a notification needs to be sent,
    // which avoids triggering IPC with usernoted on every launch.
    private func setupNotificationManager() {
        notificationManager = NotificationManager()
    }

    // MARK: - Spotlight Integration
    private func setupSpotlightIntegration() {
        searchIndexer = SearchIndexer()
        searchIndexer?.indexMedia()
    }

    // MARK: - Handle Spotlight Search Results
    func application(_ application: NSApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([NSUserActivityRestoring]) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            return true
        }
        return false
    }

    private func emitDiagnostic(_ message: String) {
        let ts = Self.diagnosticTimestampFormatter.string(from: Date())
        let line = "[\(ts)] \(message)"
        NotificationCenter.default.post(
            name: .backendStartupDiagnostic,
            object: nil,
            userInfo: ["message": line]
        )
    }

    private static let diagnosticTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    private func shouldEnableSpotlightIndexing() -> Bool {
        UserDefaults.standard.bool(forKey: "EnableDebugSpotlightIndexing")
    }
}
