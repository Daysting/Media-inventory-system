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
            CommandGroup(replacing: .appMenu) {
                Button("About Media Inventory") {
                    NSApp.orderFrontStandardAboutPanel(nil)
                }
                Divider()
                Button("Check for Updates") {
                    // TODO: Implement auto-updater
                }
                Divider()
                Button("Quit Media Inventory") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
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
