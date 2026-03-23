import Cocoa
import SwiftUI

extension Notification.Name {
    static let backendStartupDiagnostic = Notification.Name("BackendStartupDiagnostic")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var searchIndexer: SearchIndexer?
    // NotificationManager is created on demand by callers; do not instantiate at launch
    // because accessing UNUserNotificationCenter.current() triggers an XPC connection to
    // usernoted, which in turn tries task_name_for_pid on this process and logs a
    // "Unable to obtain a task name port right" kernel error.
    static var sharedNotificationManager: NotificationManager = NotificationManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        emitDiagnostic("Local mode enabled: using native SQLite datastore")
        if shouldEnableSpotlightIndexing() {
            setupSpotlightIntegration()
        } else {
            emitDiagnostic("Skipping Spotlight indexing in Debug build (toggle in Settings > Preferences)")
        }
    }

    // MARK: - Spotlight Integration
    private func setupSpotlightIntegration() {
        searchIndexer = SearchIndexer()
        searchIndexer?.indexMedia()
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
