import SwiftUI

@main
struct MediaInventoryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var apiClient = APIClient()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(apiClient)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates") {
                    // TODO: Implement auto-updater
                }
            }
            
            CommandGroup(replacing: .newItem) {
                Button("New Book") {
                    apiClient.showNewBookSheet = true
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }

        Settings {
            AppSettingsView()
        }
    }
}

private struct AppSettingsView: View {
    @AppStorage("EnableDebugSpotlightIndexing") private var enableDebugSpotlightIndexing = false
    @AppStorage("UseICloudSync") private var useICloudSync = true
    @AppStorage("ICloudDatabaseActive") private var iCloudDatabaseActive = false
    @AppStorage("ICloudLastSyncTimeInterval") private var iCloudLastSyncTimeInterval = 0.0

    var body: some View {
        Form {
            Toggle("Enable iCloud database sync", isOn: $useICloudSync)
            Text("Keeps your database in sync across Macs using the same Apple ID. Restart the app after changing this setting.")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text("Current sync status")
                Spacer()
                Text(iCloudDatabaseActive ? "Active" : "Unavailable or Disabled")
                    .foregroundColor(iCloudDatabaseActive ? .green : .secondary)
            }

            HStack {
                Text("Last iCloud sync")
                Spacer()
                Text(lastSyncLabel)
                    .foregroundColor(.secondary)
            }

            Toggle("Enable Spotlight indexing in Debug builds", isOn: $enableDebugSpotlightIndexing)
            Text("When enabled, the app will index items in Spotlight during Debug runs.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(width: 460)
    }

    private var lastSyncLabel: String {
        guard iCloudLastSyncTimeInterval > 0 else {
            return "Never"
        }

        let date = Date(timeIntervalSince1970: iCloudLastSyncTimeInterval)
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
