import Foundation
import AppKit
import SQLite3

let fm = FileManager.default
let temporary = fm.temporaryDirectory.appendingPathComponent("InventoryTests-\(UUID().uuidString)")
try fm.createDirectory(at: temporary, withIntermediateDirectories: true)
defer { try? fm.removeItem(at: temporary) }
var passed = 0
func check(_ condition: @autoclosure () throws -> Bool, _ name: String) throws {
    guard try condition() else { fatalError("FAIL: \(name)") }
    passed += 1
    print("PASS: \(name)")
}
func sql(_ url: URL, _ statement: String) throws {
    var db: OpaquePointer?
    defer { sqlite3_close(db) }
    guard sqlite3_open(url.path, &db) == SQLITE_OK,
          sqlite3_exec(db, statement, nil, nil, nil) == SQLITE_OK else {
        fatalError("SQLite setup failed: \(db.flatMap { sqlite3_errmsg($0) }.map(String.init(cString:)) ?? "open")")
    }
}
func database(_ name: String, title: String? = nil) throws -> URL {
    let url = temporary.appendingPathComponent(name)
    for table in ["books", "video_games", "movies", "electronics", "borrowers", "checkout_history"] {
        try sql(url, "CREATE TABLE \(table) (id TEXT PRIMARY KEY, title TEXT)")
    }
    if let title { try sql(url, "INSERT INTO books VALUES ('1', '\(title)')") }
    return url
}
let local = try database("local.db", title: "Original")
let cloud = temporary.appendingPathComponent("cloud.db")
let state = temporary.appendingPathComponent("state.json")
let backups = temporary.appendingPathComponent("backups")
let engine = DatabaseSnapshotSync(localURL: local, cloudURL: cloud, stateURL: state, backupsURL: backups, account: "account-a")
try check(try !engine.synchronize(), "first upload keeps local inventory")
try check(try Data(contentsOf: local) == Data(contentsOf: cloud), "cloud gets complete inventory")
try sql(local, "UPDATE books SET title = 'Local edit'")
_ = try engine.synchronize()
try check(try Data(contentsOf: local) == Data(contentsOf: cloud), "local-only change uploads")
try sql(cloud, "UPDATE books SET title = 'Remote edit'")
try check(try engine.synchronize(), "remote-only change downloads")
try check(try Data(contentsOf: local) == Data(contentsOf: cloud), "download matches cloud")
try sql(local, "UPDATE books SET title = 'Local conflict'")
try sql(cloud, "UPDATE books SET title = 'Cloud conflict'")
let beforeLocal = try Data(contentsOf: local)
let beforeCloud = try Data(contentsOf: cloud)
do { _ = try engine.synchronize(); fatalError("Conflict silently overwrote data") }
catch DatabaseSnapshotSync.SyncError.conflict { passed += 1; print("PASS: detects concurrent edits") }
try check(try beforeLocal == Data(contentsOf: local) && beforeCloud == Data(contentsOf: cloud), "conflict changes neither database")
let backupBytes = try fm.contentsOfDirectory(at: backups, includingPropertiesForKeys: nil).map { try Data(contentsOf: $0) }
try check(backupBytes.contains(beforeLocal) && backupBytes.contains(beforeCloud), "conflict preserves both inventories")
_ = try engine.synchronize(resolution: .keepCloud)
try check(try Data(contentsOf: local) == beforeCloud, "explicit cloud resolution restores chosen copy")
try sql(local, "UPDATE books SET title = 'Keep local'")
_ = try engine.synchronize(resolution: .keepLocal)
try check(try Data(contentsOf: local) == Data(contentsOf: cloud), "explicit local resolution publishes chosen copy")
let accountB = DatabaseSnapshotSync(localURL: local, cloudURL: cloud, stateURL: state, backupsURL: backups, account: "account-b")
do { _ = try accountB.synchronize(); fatalError("Account change accepted silently") }
catch DatabaseSnapshotSync.SyncError.accountChanged { passed += 1; print("PASS: account changes require a choice") }
let safeLocal = try Data(contentsOf: local)
try Data("not SQLite".utf8).write(to: cloud)
do { _ = try engine.synchronize(); fatalError("Invalid cloud database accepted") }
catch DatabaseSnapshotSync.SyncError.invalidDatabase { passed += 1; print("PASS: corrupt cloud database rejected") }
try check(try Data(contentsOf: local) == safeLocal, "corrupt cloud file leaves local data intact")
try fm.removeItem(at: cloud)
do { _ = try engine.synchronize(); fatalError("Deleted cloud document recreated silently") }
catch DatabaseSnapshotSync.SyncError.missingCloud { passed += 1; print("PASS: cloud deletion does not resurrect data") }
_ = try engine.synchronize(resolution: .keepLocal)
let empty = try database("empty.db")
let newcomer = DatabaseSnapshotSync(localURL: empty, cloudURL: cloud, stateURL: temporary.appendingPathComponent("new-state.json"), backupsURL: backups, account: "account-a")
try check(try newcomer.synchronize(), "new empty installation adopts cloud inventory")
let divergent = try database("divergent.db", title: "Another library")
let unknown = DatabaseSnapshotSync(localURL: divergent, cloudURL: cloud, stateURL: temporary.appendingPathComponent("unknown-state.json"), backupsURL: backups, account: "account-a")
do { _ = try unknown.synchronize(); fatalError("Unrelated library overwritten") }
catch DatabaseSnapshotSync.SyncError.conflict { passed += 1; print("PASS: unrelated existing libraries require a choice") }

// A legacy WAL connection must never be copied without its committed pages.
let wal = try database("wal.db", title: "WAL original")
var walConnection: OpaquePointer?
sqlite3_open(wal.path, &walConnection)
sqlite3_exec(walConnection, "PRAGMA journal_mode=WAL; UPDATE books SET title='Committed in WAL'", nil, nil, nil)
let walCloud = temporary.appendingPathComponent("wal-cloud.db")
let walEngine = DatabaseSnapshotSync(localURL: wal, cloudURL: walCloud,
    stateURL: temporary.appendingPathComponent("wal-state.json"), backupsURL: backups, account: "account-a")
do { _ = try walEngine.synchronize(); fatalError("Active WAL database was copied") }
catch DatabaseSnapshotSync.SyncError.databaseBusy { passed += 1; print("PASS: active WAL database cannot be copied") }
try check(!fm.fileExists(atPath: walCloud.path), "busy database does not create a partial cloud copy")
sqlite3_close(walConnection)
_ = try walEngine.synchronize()
try check(try Data(contentsOf: walCloud) == Data(contentsOf: wal), "closed WAL database syncs all committed pages")

// Exercise actual API operations on a disposable database without iCloud or the
// user's inventory. Pump the main loop for published completion callbacks.
let apiURL = temporary.appendingPathComponent("api.db")
setenv("MEDIA_INVENTORY_DB_PATH", apiURL.path, 1)
func wait(_ condition: () -> Bool) {
    let deadline = Date().addingTimeInterval(10)
    while !condition() && Date() < deadline { RunLoop.main.run(until: Date().addingTimeInterval(0.02)) }
    guard condition() else { fatalError("Timed out waiting for API") }
}
let api = APIClient()
api.addBook(title: "Test Book", author: nil, yearPublished: nil, publisher: nil, fictionNonfiction: nil, genre: nil, description: nil, imageUrl: nil, cost: 12.50)
wait { api.books.count == 1 || api.errorMessage != nil }
try check(api.errorMessage == nil && api.books.first?.title == "Test Book", "first launch creates schema and saves a book")
let bookID = api.books[0].id
api.addBorrower(firstName: "Test", lastName: "Borrower", address: nil, phoneNumber: nil, email: "test@example.invalid")
wait { api.borrowers.count == 1 || api.errorMessage != nil }
try check(api.errorMessage == nil && api.borrowers.first?.email == "test@example.invalid", "borrower creation succeeds")
var checkout: CheckoutBatchResult?
api.checkoutMediaBatch(borrowerID: api.borrowers[0].id, mediaIDs: [bookID]) { checkout = $0 }
wait { checkout != nil }
try check(checkout?.attempts.first?.success == true, "checkout records loan and changes item status")
var returned: ReturnBatchResult?
api.returnMediaBatch(mediaIDs: [bookID]) { returned = $0 }
wait { returned != nil }
try check(returned?.attempts.first?.success == true, "return completes loan")
let reopened = APIClient()
reopened.fetchBooks()
wait { reopened.books.count == 1 || reopened.errorMessage != nil }
try check(reopened.books.first?.status == "owned", "inventory survives reopening")
// Failure after the first statement must roll back the item status change.
try sql(apiURL, "CREATE TRIGGER reject_checkout BEFORE INSERT ON checkout_history BEGIN SELECT RAISE(ABORT, 'forced test failure'); END")
checkout = nil
api.checkoutMediaBatch(borrowerID: api.borrowers[0].id, mediaIDs: [bookID]) { checkout = $0 }
wait { checkout != nil }
try check(checkout?.attempts.first?.success == false, "checkout failure is reported")
reopened.fetchBooks()
wait { !reopened.isLoading }
try check(reopened.books.first?.status == "owned", "failed checkout rolls back item status")
try sql(apiURL, "DROP TRIGGER reject_checkout")
api.errorMessage = nil
checkout = nil
api.checkoutMediaBatch(borrowerID: api.borrowers[0].id, mediaIDs: [bookID]) { checkout = $0 }
wait { checkout != nil }
let borrowerID = api.borrowers[0].id
api.deleteBorrower(id: borrowerID)
wait { api.borrowers.isEmpty || api.errorMessage != nil }
reopened.fetchBooks()
wait { !reopened.isLoading }
try check(reopened.books.first?.status == "owned", "deleting borrower returns their active loans")
let exported = temporary.appendingPathComponent("exported.db")
api.exportInventory(to: exported)
wait { fm.fileExists(atPath: exported.path) || api.errorMessage != nil }
try check(try Data(contentsOf: exported) == Data(contentsOf: apiURL), "export preserves complete inventory")
try sql(apiURL, "UPDATE books SET title = 'Changed after backup'")
api.importInventory(from: exported)
var drained = false
ICloudDatabaseCoordinator.databaseQueue.async { DispatchQueue.main.async { drained = true } }
wait { drained }
reopened.fetchBooks()
wait { !reopened.isLoading }
try check(reopened.books.first?.title == "Test Book", "import restores an exported inventory")
let invalid = temporary.appendingPathComponent("invalid-import.db")
try Data("invalid".utf8).write(to: invalid)
api.errorMessage = nil
api.importInventory(from: invalid)
wait { api.errorMessage != nil }
try check(reopened.books.first?.title == "Test Book", "invalid import reports an error without replacing inventory")
// File image bytes must survive after the source file has disappeared.
let pixel = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1, pixelsHigh: 1, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 4, bitsPerPixel: 32)!
let png = pixel.representation(using: .png, properties: [:])!
let imageURL = temporary.appendingPathComponent("cover.png")
try png.write(to: imageURL)
let stored = try InventoryImage.storageValue(imageURL.absoluteString)
try fm.removeItem(at: imageURL)
try check(InventoryImage.data(from: stored) == png, "cover images are portable without source file paths")
try check(try InventoryImage.storageValue(stored) == stored, "editing an existing cover preserves its bytes")
print("\(passed) checks passed")
