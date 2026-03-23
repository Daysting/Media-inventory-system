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
    }
}
