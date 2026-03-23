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

    var body: some View {
        Form {
            Toggle("Enable Spotlight indexing in Debug builds", isOn: $enableDebugSpotlightIndexing)
            Text("When enabled, the app will index items in Spotlight during Debug runs.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(width: 460)
    }
}
