import Cocoa
import SwiftUI

extension Notification.Name {
    static let backendStartupDiagnostic = Notification.Name("BackendStartupDiagnostic")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var notificationManager: NotificationManager?
    var searchIndexer: SearchIndexer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureApplicationIcon()
        emitDiagnostic("Local mode enabled: using native SQLite datastore")
        setupMenuBar()
        setupNotificationManager()
        setupSpotlightIntegration()
    }

    private func configureApplicationIcon() {
        if let iconImage = NSImage(named: "AppIcon") {
            NSApp.applicationIconImage = iconImage
        }
    }

    // MARK: - Menu Bar
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "book.fill", accessibilityDescription: "Daysting's Home Inventory System")
            button.imagePosition = .imageLeading
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Dashboard", action: #selector(showDashboard), keyEquivalent: "d"))
        menu.addItem(NSMenuItem(title: "Books", action: #selector(showBooks), keyEquivalent: "b"))
        menu.addItem(NSMenuItem(title: "Video Games", action: #selector(showGames), keyEquivalent: "g"))
        menu.addItem(NSMenuItem(title: "Movies", action: #selector(showMovies), keyEquivalent: "m"))

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc private func showDashboard() {}
    @objc private func showBooks() {}
    @objc private func showGames() {}
    @objc private func showMovies() {}
    @objc private func showPreferences() {}

    // MARK: - Notifications
    private func setupNotificationManager() {
        notificationManager = NotificationManager()
        notificationManager?.requestUserPermission()
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
}
