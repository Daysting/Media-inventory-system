import Foundation

extension Notification.Name {
    static let iCloudDatabaseDidChange = Notification.Name("ICloudDatabaseDidChange")
}

/// All database reads, writes, imports and exports share this queue, including
/// clients created by Spotlight. Metadata/file-presenter callbacks never copy files.
final class ICloudDatabaseCoordinator {
    static let shared = ICloudDatabaseCoordinator()
    static let databaseQueue = DispatchQueue(label: "MediaInventory.Database", qos: .userInitiated)

    private var readyCloudPath: String?
    private var coordinatedPresenter: InventoryCloudPresenter?
    // The following monitoring properties are used exclusively on the main queue.
    private var query: NSMetadataQuery?
    private var observers: [NSObjectProtocol] = []
    private var presenter: InventoryCloudPresenter?
    private var monitoredURL: URL?

    enum CloudError: LocalizedError {
        case unavailable, downloading
        var errorDescription: String? {
            switch self {
            case .unavailable: return "iCloud is unavailable. Changes are saved on this Mac."
            case .downloading: return "Waiting for iCloud to finish downloading the inventory. Changes are saved on this Mac."
            }
        }
    }

    func synchronize(localURL: URL, resolution: DatabaseSnapshotSync.Resolution? = nil) throws -> Bool {
        dispatchPrecondition(condition: .onQueue(Self.databaseQueue))
        let fm = FileManager.default
        guard let token = fm.ubiquityIdentityToken,
              let container = fm.url(forUbiquityContainerIdentifier: "iCloud.com.erickhofer.MediaInventory") else {
            throw CloudError.unavailable
        }
        let documents = container.appendingPathComponent("Documents", isDirectory: true)
        try fm.createDirectory(at: documents, withIntermediateDirectories: true)
        let cloudURL = documents.appendingPathComponent("media_inventory.db")
        startMonitoring(cloudURL)
        guard readyCloudPath == cloudURL.path else { throw CloudError.downloading }

        let values: URLResourceValues
        do {
            values = try cloudURL.resourceValues(forKeys: [.isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey])
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            let placeholder = documents.appendingPathComponent(".media_inventory.db.icloud")
            if fm.fileExists(atPath: placeholder.path) {
                try fm.startDownloadingUbiquitousItem(at: cloudURL)
                throw CloudError.downloading
            }
            values = URLResourceValues()
        }
        if values.isUbiquitousItem == true && values.ubiquitousItemDownloadingStatus != .current {
            try fm.startDownloadingUbiquitousItem(at: cloudURL)
            throw CloudError.downloading
        }
        let tokenData = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: false)
        let folder = localURL.deletingLastPathComponent()
        let engine = DatabaseSnapshotSync(
            localURL: localURL, cloudURL: cloudURL,
            stateURL: folder.appendingPathComponent("icloud-sync-state.json"),
            backupsURL: folder.appendingPathComponent("Sync Backups", isDirectory: true),
            account: DatabaseSnapshotSync.digest(tokenData)
        )
        var coordinationError: NSError?
        var outcome: Result<Bool, Error>?
        NSFileCoordinator(filePresenter: coordinatedPresenter).coordinate(writingItemAt: cloudURL, options: .forMerging, error: &coordinationError) { url in
            outcome = Result {
                let conflicts = NSFileVersion.unresolvedConflictVersionsOfItem(at: url) ?? []
                if !conflicts.isEmpty {
                    if fm.fileExists(atPath: localURL.path) { try engine.preserve(Data(contentsOf: localURL)) }
                    if fm.fileExists(atPath: url.path) { try engine.preserve(Data(contentsOf: url)) }
                    for version in conflicts { try engine.preserve(Data(contentsOf: version.url)) }
                    guard resolution != nil else { throw DatabaseSnapshotSync.SyncError.conflict }
                }
                let changed = try engine.synchronize(resolution: resolution)
                // Only acknowledge system conflicts after preserving every version
                // and successfully applying the user's explicit resolution.
                for version in conflicts { version.isResolved = true }
                return changed
            }
        }
        if let coordinationError { throw coordinationError }
        guard let outcome else { throw CloudError.unavailable }
        let changed = try outcome.get()
        UserDefaults.standard.set(true, forKey: "ICloudDatabaseActive")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "ICloudLastSyncTimeInterval")
        let uploaded = (try? cloudURL.resourceValues(forKeys: [.ubiquitousItemIsUploadedKey]))?.ubiquitousItemIsUploaded == true
        UserDefaults.standard.set(uploaded ? "Up to date" : "Saved locally; waiting for iCloud upload", forKey: "ICloudSyncStatus")
        UserDefaults.standard.removeObject(forKey: "ICloudSyncError")
        return changed
    }

    private func startMonitoring(_ url: URL) {
        DispatchQueue.main.async {
            guard self.monitoredURL != url else { return }
            self.query?.stop()
            for observer in self.observers { NotificationCenter.default.removeObserver(observer) }
            self.observers.removeAll()
            if let presenter = self.presenter { NSFileCoordinator.removeFilePresenter(presenter) }
            self.monitoredURL = url
            let presenter = InventoryCloudPresenter(url: url)
            self.presenter = presenter
            NSFileCoordinator.addFilePresenter(presenter)

            let query = NSMetadataQuery()
            query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
            query.predicate = NSPredicate(format: "%K == %@", NSMetadataItemFSNameKey, url.lastPathComponent)
            for name in [Notification.Name.NSMetadataQueryDidFinishGathering, .NSMetadataQueryDidUpdate] {
                self.observers.append(NotificationCenter.default.addObserver(forName: name, object: query, queue: .main) { _ in
                    Self.databaseQueue.async {
                        self.coordinatedPresenter = presenter
                        self.readyCloudPath = url.path
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .iCloudDatabaseDidChange, object: nil)
                        }
                    }
                })
            }
            self.observers.append(NotificationCenter.default.addObserver(forName: .NSUbiquityIdentityDidChange, object: nil, queue: .main) { _ in
                self.monitoredURL = nil
                Self.databaseQueue.async { self.readyCloudPath = nil }
                NotificationCenter.default.post(name: .iCloudDatabaseDidChange, object: nil)
            })
            self.query = query
            query.start()
        }
    }
}

private final class InventoryCloudPresenter: NSObject, NSFilePresenter {
    let presentedItemURL: URL?
    let presentedItemOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    init(url: URL) { presentedItemURL = url }
    func presentedItemDidChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .iCloudDatabaseDidChange, object: nil)
        }
    }
    func presentedItemDidGain(_ version: NSFileVersion) { presentedItemDidChange() }
}
