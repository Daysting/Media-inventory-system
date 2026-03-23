import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var notificationManager: NotificationManager?
    var searchIndexer: SearchIndexer?
    private var flaskProcess: Process?
    private var startedFlaskProcess = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        ensureFlaskServerRunning()
        setupMenuBar()
        setupNotificationManager()
        setupSpotlightIntegration()
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopManagedFlaskServerIfNeeded()
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

    // MARK: - Flask Backend
    private func ensureFlaskServerRunning() {
        if isBackendReachable() {
            return
        }

        guard startFlaskServerProcess() else {
            print("Unable to start Flask server automatically")
            return
        }

        _ = waitForBackendReadiness(timeout: 8.0)
    }

    private func startFlaskServerProcess() -> Bool {
        guard let projectRoot = locateProjectRoot() else {
            print("Could not locate project root containing app.py")
            return false
        }

        let process = Process()
        process.currentDirectoryURL = URL(fileURLWithPath: projectRoot)

        let venvPython = "\(projectRoot)/.venv/bin/python"
        if FileManager.default.isExecutableFile(atPath: venvPython) {
            process.executableURL = URL(fileURLWithPath: venvPython)
            process.arguments = ["app.py"]
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["python3", "app.py"]
        }

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        do {
            try process.run()
            flaskProcess = process
            startedFlaskProcess = true
            print("Started Flask server from: \(projectRoot)")
            return true
        } catch {
            print("Failed to start Flask server: \(error.localizedDescription)")
            return false
        }
    }

    private func stopManagedFlaskServerIfNeeded() {
        guard startedFlaskProcess, let process = flaskProcess else {
            return
        }

        if process.isRunning {
            process.terminate()
        }

        flaskProcess = nil
        startedFlaskProcess = false
    }

    private func isBackendReachable() -> Bool {
        guard let url = URL(string: APIClient.defaultBaseURL + "/books") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 1.0

        let semaphore = DispatchSemaphore(value: 0)
        var reachable = false

        URLSession.shared.dataTask(with: request) { _, response, error in
            if error == nil, let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                reachable = true
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 1.5)
        return reachable
    }

    private func waitForBackendReadiness(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if isBackendReachable() {
                return true
            }
            Thread.sleep(forTimeInterval: 0.25)
        }
        return false
    }

    private func locateProjectRoot() -> String? {
        let fm = FileManager.default
        let envPath = ProcessInfo.processInfo.environment["MEDIA_INVENTORY_PROJECT_ROOT"]
        let userDefaultPath = UserDefaults.standard.string(forKey: "MediaInventoryProjectPath")
        let home = NSHomeDirectory()

        let candidates = [
            envPath,
            userDefaultPath,
            "\(home)/Documents/Media-inventory-system",
            "\(home)/Media-inventory-system"
        ].compactMap { $0 }

        for candidate in candidates {
            let normalized = (candidate as NSString).expandingTildeInPath
            let appPyPath = "\(normalized)/app.py"
            if fm.fileExists(atPath: appPyPath) {
                return normalized
            }
        }

        return nil
    }
}
