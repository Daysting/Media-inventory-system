import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var notificationManager: NotificationManager?
    var searchIndexer: SearchIndexer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupNotificationManager()
        setupSpotlightIntegration()
        
        // Register for notifications
        NSApplication.shared.registerForRemoteNotifications()
    }
    
    // MARK: - Menu Bar
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "book.fill", accessibilityDescription: "Media Inventory")
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
    
    @objc private func showDashboard() {
        // TODO: Navigate to dashboard
    }
    
    @objc private func showBooks() {
        // TODO: Navigate to books
    }
    
    @objc private func showGames() {
        // TODO: Navigate to games
    }
    
    @objc private func showMovies() {
        // TODO: Navigate to movies
    }
    
    @objc private func showPreferences() {
        // TODO: Show preferences window
    }
    
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
            // Handle Spotlight search result
            return true
        }
        return false
    }
}
