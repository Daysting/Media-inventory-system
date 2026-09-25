import SwiftUI

private enum AppLinks {
    static let privacyPolicy = URL(string: "https://github.com/Daysting/Media-inventory-system/blob/main/PRIVACY.md")!
    static let support = URL(string: "https://github.com/Daysting/Media-inventory-system/blob/main/SUPPORT.md")!
}

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
            CommandGroup(replacing: .newItem) {
                Button("New Book") {
                    apiClient.showNewBookSheet = true
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            CommandGroup(replacing: .help) {
                Link("DaystingInventory Support", destination: AppLinks.support)
                Link("Privacy Policy", destination: AppLinks.privacyPolicy)
            }
        }

        Settings {
            AppSettingsView()
                .environmentObject(apiClient)
        }
    }
}

private struct AppSettingsView: View {
    @EnvironmentObject var apiClient: APIClient
    @AppStorage("EnableDebugSpotlightIndexing") private var enableDebugSpotlightIndexing = false
    @AppStorage("UseICloudSync") private var useICloudSync = true
    @AppStorage("ICloudSyncStatus") private var syncStatus = "Waiting for iCloud"
    @AppStorage("ICloudSyncError") private var syncError = ""
    @State private var resolution: DatabaseSnapshotSync.Resolution?
    @State private var confirmingResolution = false
    @State private var importURL: URL?
    @State private var confirmingImport = false

    var body: some View {
        Form {
            Toggle("Enable iCloud inventory sync", isOn: $useICloudSync)
                .onChange(of: useICloudSync) { _ in apiClient.syncNow() }
            Text("Syncs your inventory and cover images across Macs using the same Apple ID. If both Macs change before syncing, you can choose which inventory to keep. Copies of both are saved for recovery.")
                .font(.caption).foregroundColor(.secondary)
            Text(syncStatus).font(.callout).textSelection(.enabled)
            HStack {
                Button("Sync Now") { apiClient.syncNow() }.disabled(!useICloudSync)
                Button("Open Sync Backups") {
                    if let folder = try? APIClient.applicationSupportDirectory().appendingPathComponent("Sync Backups", isDirectory: true) {
                        do {
                            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                            NSWorkspace.shared.open(folder)
                        } catch { apiClient.errorMessage = error.localizedDescription }
                    }
                }
            }
            if useICloudSync && !syncError.isEmpty {
                HStack {
                    Button("Use This Mac…") { resolution = .keepLocal; confirmingResolution = true }
                    Button("Use iCloud Copy…") { resolution = .keepCloud; confirmingResolution = true }
                }
            }
            Divider()
            HStack {
                Button("Export Inventory…") {
                    let panel = NSSavePanel()
                    panel.nameFieldStringValue = "media-inventory-backup.db"
                    if panel.runModal() == .OK, let url = panel.url { apiClient.exportInventory(to: url) }
                }
                Button("Import Inventory…") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    if panel.runModal() == .OK, let url = panel.url { importURL = url; confirmingImport = true }
                }
            }
            #if DEBUG
            Toggle("Enable Spotlight indexing in Debug builds", isOn: $enableDebugSpotlightIndexing)
            #endif
            Divider()
            HStack {
                Link("Support", destination: AppLinks.support)
                Spacer()
                Link("Privacy Policy", destination: AppLinks.privacyPolicy)
            }
        }
        .padding(20)
        .frame(width: 520)
        .confirmationDialog("Replace this Mac’s inventory?", isPresented: $confirmingImport) {
            Button("Import and Replace Inventory") { if let importURL { apiClient.importInventory(from: importURL) } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your current inventory will first be saved in Sync Backups. Imported changes will sync to iCloud when enabled, subject to conflict checks.")
        }
        .confirmationDialog("Choose the inventory to keep", isPresented: $confirmingResolution) {
            Button(resolution == .keepLocal ? "Keep This Mac’s Inventory" : "Keep the iCloud Inventory") {
                apiClient.syncNow(resolution: resolution)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This replaces the other inventory, including any edits unique to it. Both copies and any iCloud conflict versions will first be saved in Sync Backups on this Mac. They are not merged automatically.")
        }
    }
}
