import Foundation

extension Notification.Name {
    static let iCloudDatabaseDidChange = Notification.Name("ICloudDatabaseDidChange")
}

final class ICloudDatabaseCoordinator: NSObject {
    static let shared = ICloudDatabaseCoordinator()

    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "MediaInventory.ICloudDatabaseCoordinator", qos: .utility)

    private var metadataQuery: NSMetadataQuery?
    private var observedCloudPath: String?
    private var observedLocalPath: String?
    private var lastKnownModificationDate: Date?

    private override init() {
        super.init()
    }

    func resolveDatabasePath(preferredLocalPath: String, dbFileName: String) throws -> String {
        let localURL = URL(fileURLWithPath: preferredLocalPath)
        try ensureParentDirectoryExists(for: localURL)

        guard let cloudURL = try cloudDatabaseURL(dbFileName: dbFileName) else {
            UserDefaults.standard.set(false, forKey: "ICloudDatabaseActive")
            return preferredLocalPath
        }

        try reconcileLocalAndCloud(localURL: localURL, cloudURL: cloudURL)

        startMonitoringCloudDatabase(fileName: dbFileName, localPath: localURL.path, cloudPath: cloudURL.path)
        UserDefaults.standard.set(true, forKey: "ICloudDatabaseActive")
        return localURL.path
    }

    func syncLocalChangesToCloud(localPath: String, dbFileName: String) throws {
        guard let cloudURL = try cloudDatabaseURL(dbFileName: dbFileName) else {
            UserDefaults.standard.set(false, forKey: "ICloudDatabaseActive")
            return
        }

        let localURL = URL(fileURLWithPath: localPath)
        try ensureParentDirectoryExists(for: localURL)
        try reconcileLocalAndCloud(localURL: localURL, cloudURL: cloudURL)

        UserDefaults.standard.set(true, forKey: "ICloudDatabaseActive")
        let now = Date()
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: "ICloudLastSyncTimeInterval")
    }

    private func cloudDatabaseURL(dbFileName: String) throws -> URL? {
        guard let containerURL = fileManager.url(forUbiquityContainerIdentifier: nil) else {
            return nil
        }

        let documentsURL = containerURL.appendingPathComponent("Documents", isDirectory: true)
        try fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true)

        return documentsURL.appendingPathComponent(dbFileName, isDirectory: false)
    }

    private func ensureParentDirectoryExists(for fileURL: URL) throws {
        let parent = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
    }

    private func reconcileLocalAndCloud(localURL: URL, cloudURL: URL) throws {
        let localExists = fileManager.fileExists(atPath: localURL.path)
        let cloudExists = fileManager.fileExists(atPath: cloudURL.path)

        if localExists && !cloudExists {
            try fileManager.copyItem(at: localURL, to: cloudURL)
            return
        }

        if cloudExists && !localExists {
            try fileManager.copyItem(at: cloudURL, to: localURL)
            return
        }

        guard localExists, cloudExists else {
            return
        }

        let localDate = (try? localURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
        let cloudDate = (try? cloudURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast

        if localDate > cloudDate {
            try replaceItem(at: cloudURL, with: localURL)
            return
        }

        if cloudDate > localDate {
            try replaceItem(at: localURL, with: cloudURL)
        }
    }

    private func replaceItem(at destinationURL: URL, with sourceURL: URL) throws {
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }

    private func startMonitoringCloudDatabase(fileName: String, localPath: String, cloudPath: String) {
        DispatchQueue.main.async {
            self.observedLocalPath = localPath
            self.observedCloudPath = cloudPath
            guard self.metadataQuery == nil else { return }

            let query = NSMetadataQuery()
            query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
            query.predicate = NSPredicate(format: "%K == %@", NSMetadataItemFSNameKey, fileName)

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.handleMetadataQueryUpdate),
                name: .NSMetadataQueryDidFinishGathering,
                object: query
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.handleMetadataQueryUpdate),
                name: .NSMetadataQueryDidUpdate,
                object: query
            )

            self.metadataQuery = query
            query.start()
        }
    }

    @objc
    private func handleMetadataQueryUpdate(_ notification: Notification) {
        queue.async {
            guard let query = notification.object as? NSMetadataQuery else { return }
            query.disableUpdates()
            defer { query.enableUpdates() }

            guard let cloudPath = self.observedCloudPath else { return }
            guard let localPath = self.observedLocalPath else { return }

            for index in 0..<query.resultCount {
                guard let item = query.result(at: index) as? NSMetadataItem,
                      let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL,
                      url.path == cloudPath else {
                    continue
                }

                let modDate = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
                if let lastDate = self.lastKnownModificationDate,
                   modDate <= lastDate {
                    continue
                }

                do {
                    try self.reconcileLocalAndCloud(
                        localURL: URL(fileURLWithPath: localPath),
                        cloudURL: url
                    )
                } catch {
                    continue
                }

                self.lastKnownModificationDate = modDate
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .iCloudDatabaseDidChange, object: nil)
                }
                return
            }
        }
    }
}
