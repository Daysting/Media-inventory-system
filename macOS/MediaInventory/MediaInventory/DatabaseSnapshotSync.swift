import Foundation
import CryptoKit
import SQLite3

/// Called only while the shared database queue owns the closed local database.
/// The caller coordinates access to the cloud document for the entire operation.
struct DatabaseSnapshotSync {
    enum Resolution { case keepLocal, keepCloud }
    enum SyncError: LocalizedError {
        case conflict, accountChanged, invalidDatabase, missingCloud, databaseBusy

        var errorDescription: String? {
            switch self {
            case .conflict:
                return "Both inventories changed. Copies have been saved in Sync Backups. Choose which inventory to keep in Settings."
            case .accountChanged:
                return "The iCloud account changed. Choose an inventory in Settings before syncing with this account."
            case .invalidDatabase:
                return "An inventory file is not a valid inventory database. No existing inventory has been replaced."
            case .databaseBusy:
                return "The local inventory is still in use. Close other copies of the app before syncing."
            case .missingCloud:
                return "The iCloud inventory is missing. Choose Use This Mac in Settings to publish your local inventory again."
            }
        }
    }

    private struct State: Codable {
        let account: String
        let digest: String
    }

    let localURL: URL
    let cloudURL: URL
    let stateURL: URL
    let backupsURL: URL
    let account: String

    /// Returns true when the local database changed. No timestamp wins a conflict.
    func synchronize(resolution: Resolution? = nil) throws -> Bool {
        let fm = FileManager.default
        // Older builds or imported databases may use WAL. Bring every committed
        // page into the main file before comparing/copying it; never pair a new
        // cloud snapshot with stale SQLite sidecars.
        if fm.fileExists(atPath: localURL.path) { try prepareLocalDatabase() }
        let local = try fm.fileExists(atPath: localURL.path) ? Data(contentsOf: localURL) : nil
        let cloud = try fm.fileExists(atPath: cloudURL.path) ? Data(contentsOf: cloudURL) : nil
        let state: State? = try fm.fileExists(atPath: stateURL.path)
            ? JSONDecoder().decode(State.self, from: Data(contentsOf: stateURL)) : nil

        if let state, state.account != account, resolution == nil {
            throw SyncError.accountChanged
        }
        let baseline = state?.account == account ? state?.digest : nil

        if let resolution {
            if let local { try preserve(local) }
            if let cloud { try preserve(cloud) }
            switch resolution {
            case .keepLocal:
                guard let local else { throw SyncError.invalidDatabase }
                try validate(local)
                try local.write(to: cloudURL, options: .atomic)
                try saveState(local)
                return false
            case .keepCloud:
                guard let cloud else { throw SyncError.missingCloud }
                try validate(cloud)
                try cloud.write(to: localURL, options: .atomic)
                try saveState(cloud)
                return true
            }
        }

        switch (local, cloud) {
        case (nil, nil):
            return false
        case (let local?, nil):
            // Do not silently resurrect a cloud document deleted on another Mac.
            guard baseline == nil else { throw SyncError.missingCloud }
            try validate(local)
            try local.write(to: cloudURL, options: .atomic)
            try saveState(local)
            return false
        case (nil, let cloud?):
            try validate(cloud)
            try cloud.write(to: localURL, options: .atomic)
            try saveState(cloud)
            return true
        case (let local?, let cloud?):
            let localHash = Self.digest(local)
            let cloudHash = Self.digest(cloud)
            if localHash == cloudHash {
                try saveState(local)
                return false
            }
            if cloudHash == baseline {
                try validate(local)
                try preserve(cloud)
                try local.write(to: cloudURL, options: .atomic)
                try saveState(local)
                return false
            }
            // A new installation may have initialized an empty database offline.
            let newEmptyInventory = try baseline == nil ? isEmpty(local) : false
            if localHash == baseline || newEmptyInventory {
                try validate(cloud)
                try preserve(local)
                try cloud.write(to: localURL, options: .atomic)
                try saveState(cloud)
                return true
            }
            try preserve(local)
            try preserve(cloud)
            throw SyncError.conflict
        }
    }

    private func prepareLocalDatabase() throws {
        var db: OpaquePointer?
        defer { sqlite3_close(db) }
        guard sqlite3_open_v2(localURL.path, &db, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK else {
            throw SyncError.invalidDatabase
        }
        sqlite3_busy_timeout(db, 1000)
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(db, "PRAGMA journal_mode = DELETE", -1, &statement, nil) == SQLITE_OK else {
            throw SyncError.invalidDatabase
        }
        guard sqlite3_step(statement) == SQLITE_ROW,
              let mode = sqlite3_column_text(statement, 0), String(cString: mode).lowercased() == "delete" else {
            throw SyncError.databaseBusy
        }
    }

    func preserve(_ data: Data) throws {
        try FileManager.default.createDirectory(at: backupsURL, withIntermediateDirectories: true)
        let url = backupsURL.appendingPathComponent("inventory-\(Self.digest(data)).db")
        if !FileManager.default.fileExists(atPath: url.path) {
            try data.write(to: url, options: .atomic)
        }
    }

    static func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func saveState(_ data: Data) throws {
        try JSONEncoder().encode(State(account: account, digest: Self.digest(data)))
            .write(to: stateURL, options: .atomic)
    }

    func validate(_ data: Data) throws {
        _ = try inspect(data)
    }

    private func isEmpty(_ data: Data) throws -> Bool { try inspect(data) == 0 }

    private func inspect(_ data: Data) throws -> Int {
        let temporary = localURL.deletingLastPathComponent().appendingPathComponent(".validate-\(UUID().uuidString).db")
        try data.write(to: temporary, options: .atomic)
        defer { try? FileManager.default.removeItem(at: temporary) }
        var db: OpaquePointer?
        defer { sqlite3_close(db) }
        guard sqlite3_open_v2(temporary.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            throw SyncError.invalidDatabase
        }
        var check: OpaquePointer?
        defer { sqlite3_finalize(check) }
        guard sqlite3_prepare_v2(db, "PRAGMA quick_check", -1, &check, nil) == SQLITE_OK,
              sqlite3_step(check) == SQLITE_ROW,
              let result = sqlite3_column_text(check, 0), String(cString: result) == "ok" else {
            throw SyncError.invalidDatabase
        }
        var count = 0
        for table in ["books", "video_games", "movies", "electronics", "borrowers", "checkout_history"] {
            var stmt: OpaquePointer?
            defer { sqlite3_finalize(stmt) }
            guard sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM \(table)", -1, &stmt, nil) == SQLITE_OK,
                  sqlite3_step(stmt) == SQLITE_ROW else { throw SyncError.invalidDatabase }
            count += Int(sqlite3_column_int(stmt, 0))
        }
        return count
    }
}
