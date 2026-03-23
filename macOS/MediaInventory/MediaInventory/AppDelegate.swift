import Cocoa
import Network
import SwiftUI

extension Notification.Name {
    static let backendStartupDiagnostic = Notification.Name("BackendStartupDiagnostic")
}

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
        emitDiagnostic("Backend startup check initiated")
        if let reachableBaseURL = firstReachableBackendBaseURL() {
            APIClient.persistBaseURL(reachableBaseURL)
            emitDiagnostic("Using existing backend at \(reachableBaseURL)")
            return
        }

        emitDiagnostic("No reachable backend detected, attempting managed launch")
        for port in APIClient.preferredPorts where isLocalPortAvailable(port) {
            emitDiagnostic("Port \(port) is available; attempting launch")
            guard startFlaskServerProcess(port: port) else {
                emitDiagnostic("Launch attempt on port \(port) failed")
                continue
            }

            let baseURL = APIClient.baseURL(for: port)
            if waitForBackendReadiness(baseURL: baseURL, timeout: 8.0) {
                APIClient.persistBaseURL(baseURL)
                emitDiagnostic("Backend ready at \(baseURL)")
                return
            }

            emitDiagnostic("Backend on port \(port) did not become ready in time; stopping process")
            stopManagedFlaskServerIfNeeded()
        }

        for port in APIClient.preferredPorts where !isLocalPortAvailable(port) {
            emitDiagnostic("Port \(port) is in use by another process")
        }

        print("Unable to start Flask server automatically on ports: \(APIClient.preferredPorts)")
        emitDiagnostic("Unable to start backend automatically on preferred ports")
    }

    private func startFlaskServerProcess(port: Int) -> Bool {
        guard let projectRoot = locateProjectRoot() else {
            print("Could not locate project root containing app.py")
            emitDiagnostic("Could not locate project root containing app.py")
            return false
        }
        emitDiagnostic("Project root resolved: \(projectRoot)")

        let process = Process()
        process.currentDirectoryURL = URL(fileURLWithPath: projectRoot)
        var environment = ProcessInfo.processInfo.environment
        environment["MEDIA_INVENTORY_PORT"] = String(port)
        environment["MEDIA_INVENTORY_MANAGED_LAUNCH"] = "1"
        environment["PYTHONUNBUFFERED"] = "1"
        process.environment = environment

        let pythonCandidates = [
            "\(projectRoot)/.venv/bin/python",
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3",
            "/usr/bin/python3"
        ]

        if let pythonPath = pythonCandidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            process.executableURL = URL(fileURLWithPath: pythonPath)
            process.arguments = ["app.py"]
            emitDiagnostic("Using Python executable: \(pythonPath)")
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["python3", "app.py"]
            emitDiagnostic("Using fallback Python executable: /usr/bin/env python3")
        }

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        do {
            try process.run()
            flaskProcess = process
            startedFlaskProcess = true
            print("Started Flask server from: \(projectRoot) on port \(port)")
            emitDiagnostic("Started Flask process on port \(port) (pid: \(process.processIdentifier))")
            return true
        } catch {
            print("Failed to start Flask server: \(error.localizedDescription)")
            emitDiagnostic("Failed to start Flask process: \(error.localizedDescription)")
            return false
        }
    }

    private func stopManagedFlaskServerIfNeeded() {
        guard startedFlaskProcess, let process = flaskProcess else {
            return
        }

        if process.isRunning {
            process.terminate()
            emitDiagnostic("Stopped managed Flask process")
        }

        flaskProcess = nil
        startedFlaskProcess = false
    }

    private func firstReachableBackendBaseURL() -> String? {
        for baseURL in APIClient.candidateBaseURLs where isBackendReachable(baseURL: baseURL) {
            return baseURL
        }

        return nil
    }

    private func isBackendReachable(baseURL: String) -> Bool {
        guard let url = URL(string: baseURL + APIClient.backendValidationPath) else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 1.0

        let semaphore = DispatchSemaphore(value: 0)
        var reachable = false

        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil,
               let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode),
               let data,
               let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               jsonObject["success"] as? Bool == true,
               jsonObject["stats"] as? [String: Any] != nil {
                reachable = true
            }
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 1.5)
        return reachable
    }

    private func waitForBackendReadiness(baseURL: String, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if isBackendReachable(baseURL: baseURL) {
                return true
            }
            Thread.sleep(forTimeInterval: 0.25)
        }
        return false
    }

    private func isLocalPortAvailable(_ port: Int) -> Bool {
        guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else {
            return false
        }

        do {
            let listener = try NWListener(using: .tcp, on: nwPort)
            listener.cancel()
            return true
        } catch {
            return false
        }
    }

    private func locateProjectRoot() -> String? {
        let fm = FileManager.default
        let envPath = ProcessInfo.processInfo.environment["MEDIA_INVENTORY_PROJECT_ROOT"]
        let userDefaultPath = UserDefaults.standard.string(forKey: "MediaInventoryProjectPath")
        let home = NSHomeDirectory()
        let cwd = fm.currentDirectoryPath
        let bundlePath = Bundle.main.bundleURL.path

        let candidates = [
            envPath,
            userDefaultPath,
            cwd,
            "\(home)/Media-inventory-system",
            "\(home)/Documents/Media-inventory-system"
        ].compactMap { $0 }

        for candidate in candidates {
            let normalized = (candidate as NSString).expandingTildeInPath
            let appPyPath = "\(normalized)/app.py"
            if fm.fileExists(atPath: appPyPath) {
                return normalized
            }
        }

        // Fallback: walk up from app bundle path to find app.py in parent directories.
        var currentPath = (bundlePath as NSString).deletingLastPathComponent
        for _ in 0..<8 {
            let appPyPath = (currentPath as NSString).appendingPathComponent("app.py")
            if fm.fileExists(atPath: appPyPath) {
                return currentPath
            }
            let parent = (currentPath as NSString).deletingLastPathComponent
            if parent == currentPath {
                break
            }
            currentPath = parent
        }

        return nil
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
