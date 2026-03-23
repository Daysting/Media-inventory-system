import Foundation
import Combine
import SQLite3

class APIClient: ObservableObject {
    @Published var books: [Book] = []
    @Published var games: [Game] = []
    @Published var movies: [Movie] = []
    @Published var borrowers: [Borrower] = []

    // MARK: - Report State
    @Published var inventorySummary: InventorySummaryReport?
    @Published var borrowerActivity: [BorrowerActivityEntry] = []
    @Published var checkoutHistoryEntries: [CheckoutHistoryEntry] = []
    @Published var genreDistribution: GenreDistributionReport?
    @Published var overdueItems: [OverdueItem] = []
    @Published var mostPopular: MostPopularReport?
    @Published var isLoadingReport = false

    // MARK: - Diagnostics State
    @Published var diagnosticsStats: DiagnosticsStats?
    @Published var dbHealthy: Bool?
    @Published var isLoadingDiagnostics = false
    @Published var isCheckingIntegrity = false
    @Published var isRepairing = false
    @Published var lastRepairSuccess: Bool?

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showNewBookSheet = false

    private let dbQueue = DispatchQueue(label: "MediaInventory.DatabaseQueue", qos: .userInitiated)
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    init() {
        do {
            try ensureDatabaseInitialized()
        } catch {
            errorMessage = "Failed to initialize database: \(error.localizedDescription)"
        }
    }

    // MARK: - Books
    func fetchBooks() {
        isLoading = true
        runAsync {
            var rows: [[String: Any]] = []
            try self.withDatabase { db in
                let sql = """
                SELECT id, title, author, year_published, publisher, fiction_nonfiction, genre, description, image_url, status
                FROM books
                ORDER BY title
                """
                var stmt: OpaquePointer?
                defer { sqlite3_finalize(stmt) }
                try self.require(sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, db: db)

                while sqlite3_step(stmt) == SQLITE_ROW {
                    rows.append([
                        "id": self.columnText(stmt, 0) ?? UUID().uuidString,
                        "title": self.columnText(stmt, 1) ?? "Untitled",
                        "author": self.columnText(stmt, 2) as Any,
                        "year_published": self.columnInt(stmt, 3) as Any,
                        "publisher": self.columnText(stmt, 4) as Any,
                        "fiction_nonfiction": self.columnText(stmt, 5) as Any,
                        "genre": self.columnText(stmt, 6) as Any,
                        "description": self.columnText(stmt, 7) as Any,
                        "image_url": self.columnText(stmt, 8) as Any,
                        "status": self.columnText(stmt, 9) ?? "owned"
                    ])
                }
            }

            let data = try JSONSerialization.data(withJSONObject: ["success": true, "books": rows])
            let decoded = try JSONDecoder().decode(BooksResponse.self, from: data)
            DispatchQueue.main.async {
                self.books = decoded.books
                self.isLoading = false
            }
        } onError: { error in
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }

    func addBook(title: String, author: String?, yearPublished: Int?, publisher: String?,
                 fictionNonfiction: String?, genre: String?, description: String?, imageUrl: String?) {
        runAsync {
            try self.withDatabase { db in
                let id = try self.generateMediaID(prefix: "319721", digits: 8, table: "books", db: db)
                let sql = """
                INSERT INTO books (id, title, author, year_published, publisher, fiction_nonfiction, genre, description, image_url, status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'owned')
                """
                var stmt: OpaquePointer?
                defer { sqlite3_finalize(stmt) }
                try self.require(sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, db: db)
                self.bindText(stmt, 1, id)
                self.bindText(stmt, 2, title)
                self.bindOptionalText(stmt, 3, author)
                self.bindOptionalInt(stmt, 4, yearPublished)
                self.bindOptionalText(stmt, 5, publisher)
                self.bindOptionalText(stmt, 6, fictionNonfiction)
                self.bindOptionalText(stmt, 7, genre)
                self.bindOptionalText(stmt, 8, description)
                self.bindOptionalText(stmt, 9, imageUrl)
                try self.require(sqlite3_step(stmt) == SQLITE_DONE, db: db)
            }
            DispatchQueue.main.async { self.fetchBooks() }
        } onError: { error in
            self.errorMessage = error.localizedDescription
        }
    }

    func deleteBook(id: String) {
        runAsync {
            try self.withDatabase { db in
                try self.execute(db, sql: "DELETE FROM checkout_history WHERE media_id = ? AND media_type = 'books'", bind: { stmt in
                    self.bindText(stmt, 1, id)
                })
                try self.execute(db, sql: "DELETE FROM books WHERE id = ?", bind: { stmt in
                    self.bindText(stmt, 1, id)
                })
            }
            DispatchQueue.main.async { self.fetchBooks() }
        } onError: { error in
            self.errorMessage = error.localizedDescription
        }
    }

    func updateBook(id: String, title: String, author: String?, yearPublished: Int?,
                    publisher: String?, fictionNonfiction: String?, genre: String?,
                    description: String?, imageUrl: String?) {
        runAsync {
            try self.withDatabase { db in
                let sql = """
                UPDATE books
                SET title = ?, author = ?, year_published = ?, publisher = ?, fiction_nonfiction = ?, genre = ?, description = ?, image_url = ?
                WHERE id = ?
                """
                try self.execute(db, sql: sql, bind: { stmt in
                    self.bindText(stmt, 1, title)
                    self.bindOptionalText(stmt, 2, author)
                    self.bindOptionalInt(stmt, 3, yearPublished)
                    self.bindOptionalText(stmt, 4, publisher)
                    self.bindOptionalText(stmt, 5, fictionNonfiction)
                    self.bindOptionalText(stmt, 6, genre)
                    self.bindOptionalText(stmt, 7, description)
                    self.bindOptionalText(stmt, 8, imageUrl)
                    self.bindText(stmt, 9, id)
                })
            }
            DispatchQueue.main.async { self.fetchBooks() }
        } onError: { error in
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Games
    func fetchGames() {
        isLoading = true
        runAsync {
            var rows: [[String: Any]] = []
            try self.withDatabase { db in
                let sql = """
                SELECT id, title, game_system, genre, year_released, image_url, status
                FROM video_games
                ORDER BY title
                """
                var stmt: OpaquePointer?
                defer { sqlite3_finalize(stmt) }
                try self.require(sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, db: db)

                while sqlite3_step(stmt) == SQLITE_ROW {
                    let gameSystem = self.columnText(stmt, 2)
                    rows.append([
                        "id": self.columnText(stmt, 0) ?? UUID().uuidString,
                        "title": self.columnText(stmt, 1) ?? "Untitled",
                        "developer": gameSystem as Any,
                        "platform": gameSystem as Any,
                        "year_released": self.columnInt(stmt, 4) as Any,
                        "genre": self.columnText(stmt, 3) as Any,
                        "rating": NSNull(),
                        "description": NSNull(),
                        "image_url": self.columnText(stmt, 5) as Any,
                        "status": self.columnText(stmt, 6) ?? "owned"
                    ])
                }
            }

            let data = try JSONSerialization.data(withJSONObject: ["success": true, "games": rows])
            let decoded = try JSONDecoder().decode(GamesResponse.self, from: data)
            DispatchQueue.main.async {
                self.games = decoded.games
                self.isLoading = false
            }
        } onError: { error in
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }

    func addGame(title: String, developer: String?, platform: String?, yearReleased: Int?,
                 genre: String?, rating: String?, imageUrl: String?) {
        let gameSystem = platform ?? developer
        runAsync {
            try self.withDatabase { db in
                let id = try self.generateMediaID(prefix: "319722", digits: 8, table: "video_games", db: db)
                let sql = """
                INSERT INTO video_games (id, title, game_system, genre, year_released, image_url, status)
                VALUES (?, ?, ?, ?, ?, ?, 'owned')
                """
                try self.execute(db, sql: sql, bind: { stmt in
                    self.bindText(stmt, 1, id)
                    self.bindText(stmt, 2, title)
                    self.bindOptionalText(stmt, 3, gameSystem)
                    self.bindOptionalText(stmt, 4, genre)
                    self.bindOptionalInt(stmt, 5, yearReleased)
                    self.bindOptionalText(stmt, 6, imageUrl)
                })
            }
            DispatchQueue.main.async { self.fetchGames() }
        } onError: { error in
            self.errorMessage = error.localizedDescription
        }
    }

    func deleteGame(id: String) {
        runAsync {
            try self.withDatabase { db in
                try self.execute(db, sql: "DELETE FROM checkout_history WHERE media_id = ? AND media_type = 'video_games'", bind: { stmt in
                    self.bindText(stmt, 1, id)
                })
                try self.execute(db, sql: "DELETE FROM video_games WHERE id = ?", bind: { stmt in
                    self.bindText(stmt, 1, id)
                })
            }
            DispatchQueue.main.async { self.fetchGames() }
        } onError: { error in
            self.errorMessage = error.localizedDescription
        }
    }

    func updateGame(id: String, title: String, platform: String?, genre: String?,
                    yearReleased: Int?, imageUrl: String?) {
        runAsync {
            try self.withDatabase { db in
                let sql = """
                UPDATE video_games
                SET title = ?, game_system = ?, genre = ?, year_released = ?, image_url = ?
                WHERE id = ?
                """
                try self.execute(db, sql: sql, bind: { stmt in
                    self.bindText(stmt, 1, title)
                    self.bindOptionalText(stmt, 2, platform)
                    self.bindOptionalText(stmt, 3, genre)
                    self.bindOptionalInt(stmt, 4, yearReleased)
                    self.bindOptionalText(stmt, 5, imageUrl)
                    self.bindText(stmt, 6, id)
                })
            }
            DispatchQueue.main.async { self.fetchGames() }
        } onError: { error in
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Movies
    func fetchMovies() {
        isLoading = true
        runAsync {
            var results: [Movie] = []
            try self.withDatabase { db in
                let sql = """
                SELECT id, title, director, "cast", year_released, studio, genre, format, image_url, status
                FROM movies
                ORDER BY title
                """
                var stmt: OpaquePointer?
                defer { sqlite3_finalize(stmt) }
                try self.require(sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, db: db)

                while sqlite3_step(stmt) == SQLITE_ROW {
                    results.append(
                        Movie(
                            id: self.columnText(stmt, 0) ?? UUID().uuidString,
                            title: self.columnText(stmt, 1) ?? "Untitled",
                            director: self.columnText(stmt, 2),
                            cast: self.columnText(stmt, 3),
                            yearReleased: self.columnInt(stmt, 4),
                            studio: self.columnText(stmt, 5),
                            genre: self.columnText(stmt, 6),
                            rating: self.columnText(stmt, 7),
                            runtimeMinutes: nil,
                            imageUrl: self.columnText(stmt, 8),
                            status: self.columnText(stmt, 9) ?? "owned"
                        )
                    )
                }
            }

            DispatchQueue.main.async {
                self.movies = results
                self.isLoading = false
            }
        } onError: { error in
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }

    func addMovie(title: String, director: String?, yearReleased: Int?, genre: String?,
                  rating: String?, runtimeMinutes: Int?, imageUrl: String?) {
        runAsync {
            try self.withDatabase { db in
                let id = try self.generateMediaID(prefix: "319723", digits: 8, table: "movies", db: db)
                let sql = """
                INSERT INTO movies (id, title, director, "cast", year_released, studio, genre, format, image_url, status)
                VALUES (?, ?, ?, NULL, ?, NULL, ?, ?, ?, 'owned')
                """
                try self.execute(db, sql: sql, bind: { stmt in
                    self.bindText(stmt, 1, id)
                    self.bindText(stmt, 2, title)
                    self.bindOptionalText(stmt, 3, director)
                    self.bindOptionalInt(stmt, 4, yearReleased)
                    self.bindOptionalText(stmt, 5, genre)
                    self.bindOptionalText(stmt, 6, rating)
                    self.bindOptionalText(stmt, 7, imageUrl)
                })
            }
            DispatchQueue.main.async { self.fetchMovies() }
        } onError: { error in
            self.errorMessage = error.localizedDescription
        }
    }

    func deleteMovie(id: String) {
        runAsync {
            try self.withDatabase { db in
                try self.execute(db, sql: "DELETE FROM checkout_history WHERE media_id = ? AND media_type = 'movies'", bind: { stmt in
                    self.bindText(stmt, 1, id)
                })
                try self.execute(db, sql: "DELETE FROM movies WHERE id = ?", bind: { stmt in
                    self.bindText(stmt, 1, id)
                })
            }
            DispatchQueue.main.async { self.fetchMovies() }
        } onError: { error in
            self.errorMessage = error.localizedDescription
        }
    }

    func updateMovie(id: String, title: String, director: String?, cast: String?,
                     yearReleased: Int?, studio: String?, genre: String?,
                     rating: String?, imageUrl: String?) {
        runAsync {
            try self.withDatabase { db in
                let sql = """
                UPDATE movies
                SET title = ?, director = ?, "cast" = ?, year_released = ?, studio = ?, genre = ?, format = ?, image_url = ?
                WHERE id = ?
                """
                try self.execute(db, sql: sql, bind: { stmt in
                    self.bindText(stmt, 1, title)
                    self.bindOptionalText(stmt, 2, director)
                    self.bindOptionalText(stmt, 3, cast)
                    self.bindOptionalInt(stmt, 4, yearReleased)
                    self.bindOptionalText(stmt, 5, studio)
                    self.bindOptionalText(stmt, 6, genre)
                    self.bindOptionalText(stmt, 7, rating)
                    self.bindOptionalText(stmt, 8, imageUrl)
                    self.bindText(stmt, 9, id)
                })
            }
            DispatchQueue.main.async { self.fetchMovies() }
        } onError: { error in
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Borrowers
    func fetchBorrowers() {
        isLoading = true
        runAsync {
            var results: [Borrower] = []
            try self.withDatabase { db in
                let sql = "SELECT id, first_name, last_name, address, phone_number FROM borrowers ORDER BY last_name, first_name"
                var stmt: OpaquePointer?
                defer { sqlite3_finalize(stmt) }
                try self.require(sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, db: db)

                while sqlite3_step(stmt) == SQLITE_ROW {
                    results.append(
                        Borrower(
                            id: self.columnText(stmt, 0) ?? UUID().uuidString,
                            firstName: self.columnText(stmt, 1) ?? "Unknown",
                            lastName: self.columnText(stmt, 2) ?? "Borrower",
                            address: self.columnText(stmt, 3),
                            phoneNumber: self.columnText(stmt, 4),
                            email: nil
                        )
                    )
                }
            }

            DispatchQueue.main.async {
                self.borrowers = results
                self.isLoading = false
            }
        } onError: { error in
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }

    func addBorrower(firstName: String, lastName: String, address: String?, phoneNumber: String?, email: String?) {
        runAsync {
            try self.withDatabase { db in
                let id = try self.generateBorrowerID(db: db)
                let sql = "INSERT INTO borrowers (id, first_name, last_name, address, phone_number) VALUES (?, ?, ?, ?, ?)"
                try self.execute(db, sql: sql, bind: { stmt in
                    self.bindText(stmt, 1, id)
                    self.bindText(stmt, 2, firstName)
                    self.bindText(stmt, 3, lastName)
                    self.bindOptionalText(stmt, 4, address)
                    self.bindOptionalText(stmt, 5, phoneNumber)
                })
            }
            DispatchQueue.main.async { self.fetchBorrowers() }
        } onError: { error in
            self.errorMessage = error.localizedDescription
        }
    }

    func deleteBorrower(id: String) {
        runAsync {
            try self.withDatabase { db in
                try self.execute(db, sql: "DELETE FROM checkout_history WHERE borrower_id = ?", bind: { stmt in
                    self.bindText(stmt, 1, id)
                })
                try self.execute(db, sql: "DELETE FROM borrowers WHERE id = ?", bind: { stmt in
                    self.bindText(stmt, 1, id)
                })
            }
            DispatchQueue.main.async { self.fetchBorrowers() }
        } onError: { error in
            self.errorMessage = error.localizedDescription
        }
    }

    func updateBorrower(id: String, firstName: String, lastName: String,
                        address: String?, phoneNumber: String?) {
        runAsync {
            try self.withDatabase { db in
                let sql = "UPDATE borrowers SET first_name = ?, last_name = ?, address = ?, phone_number = ? WHERE id = ?"
                try self.execute(db, sql: sql, bind: { stmt in
                    self.bindText(stmt, 1, firstName)
                    self.bindText(stmt, 2, lastName)
                    self.bindOptionalText(stmt, 3, address)
                    self.bindOptionalText(stmt, 4, phoneNumber)
                    self.bindText(stmt, 5, id)
                })
            }
            DispatchQueue.main.async { self.fetchBorrowers() }
        } onError: { error in
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Reports
    func fetchInventorySummary() {
        isLoadingReport = true
        runAsync {
            var report = InventorySummaryReport(
                books: .init(total: 0, owned: 0),
                videoGames: .init(total: 0, owned: 0),
                movies: .init(total: 0, owned: 0),
                borrowersTotal: 0,
                currentlyCheckedOut: 0,
                totalCheckoutHistory: 0
            )

            try self.withDatabase { db in
                let booksStats = try self.countAndOwned(db: db, table: "books")
                let gamesStats = try self.countAndOwned(db: db, table: "video_games")
                let moviesStats = try self.countAndOwned(db: db, table: "movies")
                let borrowersTotal = try self.scalarInt(db, sql: "SELECT COUNT(*) FROM borrowers")
                let checkedOut = try self.scalarInt(db, sql: "SELECT COUNT(*) FROM checkout_history WHERE status = 'checked_out'")
                let totalHistory = try self.scalarInt(db, sql: "SELECT COUNT(*) FROM checkout_history WHERE status = 'returned'")

                report = InventorySummaryReport(
                    books: .init(total: booksStats.total, owned: booksStats.owned),
                    videoGames: .init(total: gamesStats.total, owned: gamesStats.owned),
                    movies: .init(total: moviesStats.total, owned: moviesStats.owned),
                    borrowersTotal: borrowersTotal,
                    currentlyCheckedOut: checkedOut,
                    totalCheckoutHistory: totalHistory
                )
            }

            DispatchQueue.main.async {
                self.inventorySummary = report
                self.isLoadingReport = false
            }
        } onError: { error in
            self.errorMessage = error.localizedDescription
            self.isLoadingReport = false
        }
    }

    func fetchBorrowerActivity() {
        isLoadingReport = true
        runAsync {
            var results: [BorrowerActivityEntry] = []
            try self.withDatabase { db in
                let sql = """
                SELECT b.id, b.first_name, b.last_name,
                       COUNT(CASE WHEN ch.status = 'checked_out' THEN 1 END),
                       COUNT(CASE WHEN ch.status = 'returned' THEN 1 END),
                       MAX(ch.checkout_date)
                FROM borrowers b
                LEFT JOIN checkout_history ch ON b.id = ch.borrower_id
                GROUP BY b.id, b.first_name, b.last_name
                ORDER BY 5 DESC, 4 DESC
                """
                var stmt: OpaquePointer?
                defer { sqlite3_finalize(stmt) }
                try self.require(sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, db: db)

                while sqlite3_step(stmt) == SQLITE_ROW {
                    results.append(
                        BorrowerActivityEntry(
                            id: self.columnText(stmt, 0) ?? UUID().uuidString,
                            name: "\(self.columnText(stmt, 1) ?? "") \(self.columnText(stmt, 2) ?? "")".trimmingCharacters(in: .whitespaces),
                            currentlyCheckedOut: self.columnInt(stmt, 3) ?? 0,
                            totalReturned: self.columnInt(stmt, 4) ?? 0,
                            lastActivity: self.columnText(stmt, 5) ?? ""
                        )
                    )
                }
            }

            DispatchQueue.main.async {
                self.borrowerActivity = results
                self.isLoadingReport = false
            }
        } onError: { error in
            self.errorMessage = error.localizedDescription
            self.isLoadingReport = false
        }
    }

    func fetchCheckoutHistoryReport() {
        isLoadingReport = true
        runAsync {
            var results: [CheckoutHistoryEntry] = []
            try self.withDatabase { db in
                let sql = """
                SELECT ch.id,
                       b.first_name,
                       b.last_name,
                       CASE
                         WHEN ch.media_type = 'books' THEN bk.title
                         WHEN ch.media_type = 'video_games' THEN vg.title
                         WHEN ch.media_type = 'movies' THEN mv.title
                         ELSE ch.media_id
                       END,
                       ch.media_type,
                       ch.checkout_date,
                       ch.return_date,
                       ch.status
                FROM checkout_history ch
                JOIN borrowers b ON ch.borrower_id = b.id
                LEFT JOIN books bk ON ch.media_type = 'books' AND ch.media_id = bk.id
                LEFT JOIN video_games vg ON ch.media_type = 'video_games' AND ch.media_id = vg.id
                LEFT JOIN movies mv ON ch.media_type = 'movies' AND ch.media_id = mv.id
                ORDER BY ch.checkout_date DESC
                """
                var stmt: OpaquePointer?
                defer { sqlite3_finalize(stmt) }
                try self.require(sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, db: db)

                while sqlite3_step(stmt) == SQLITE_ROW {
                    results.append(
                        CheckoutHistoryEntry(
                            id: String(self.columnInt(stmt, 0) ?? 0),
                            borrowerName: "\(self.columnText(stmt, 1) ?? "") \(self.columnText(stmt, 2) ?? "")".trimmingCharacters(in: .whitespaces),
                            mediaTitle: self.columnText(stmt, 3) ?? "—",
                            mediaType: self.columnText(stmt, 4) ?? "",
                            checkoutDate: self.columnText(stmt, 5) ?? "",
                            returnDate: self.columnText(stmt, 6),
                            status: self.columnText(stmt, 7) ?? "returned"
                        )
                    )
                }
            }

            DispatchQueue.main.async {
                self.checkoutHistoryEntries = results
                self.isLoadingReport = false
            }
        } onError: { error in
            self.errorMessage = error.localizedDescription
            self.isLoadingReport = false
        }
    }

    func fetchGenreDistribution() {
        isLoadingReport = true
        runAsync {
            func loadGenres(db: OpaquePointer?, table: String) throws -> [GenreCount] {
                var items: [GenreCount] = []
                let sql = "SELECT genre, COUNT(*) FROM \(table) WHERE genre IS NOT NULL AND genre != '' GROUP BY genre ORDER BY COUNT(*) DESC"
                var stmt: OpaquePointer?
                defer { sqlite3_finalize(stmt) }
                try self.require(sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, db: db)
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let name = self.columnText(stmt, 0) ?? "Unknown"
                    let count = self.columnInt(stmt, 1) ?? 0
                    items.append(GenreCount(name: name, count: count))
                }
                return items
            }

            var report = GenreDistributionReport(books: [], videoGames: [], movies: [])
            try self.withDatabase { db in
                report = GenreDistributionReport(
                    books: try loadGenres(db: db, table: "books"),
                    videoGames: try loadGenres(db: db, table: "video_games"),
                    movies: try loadGenres(db: db, table: "movies")
                )
            }

            DispatchQueue.main.async {
                self.genreDistribution = report
                self.isLoadingReport = false
            }
        } onError: { error in
            self.errorMessage = error.localizedDescription
            self.isLoadingReport = false
        }
    }

    func fetchOverdueItems() {
        isLoadingReport = true
        runAsync {
            let threshold = APIClient.dateFormatter.string(from: Date().addingTimeInterval(-30 * 24 * 60 * 60))
            var results: [OverdueItem] = []

            try self.withDatabase { db in
                let sql = """
                SELECT ch.media_id,
                       ch.media_type,
                       CASE
                         WHEN ch.media_type = 'books' THEN bk.title
                         WHEN ch.media_type = 'video_games' THEN vg.title
                         WHEN ch.media_type = 'movies' THEN mv.title
                         ELSE ch.media_id
                       END,
                       b.first_name,
                       b.last_name,
                       ch.checkout_date
                FROM checkout_history ch
                JOIN borrowers b ON ch.borrower_id = b.id
                LEFT JOIN books bk ON ch.media_type = 'books' AND ch.media_id = bk.id
                LEFT JOIN video_games vg ON ch.media_type = 'video_games' AND ch.media_id = vg.id
                LEFT JOIN movies mv ON ch.media_type = 'movies' AND ch.media_id = mv.id
                WHERE ch.status = 'checked_out' AND ch.checkout_date < ?
                ORDER BY ch.checkout_date ASC
                """

                var stmt: OpaquePointer?
                defer { sqlite3_finalize(stmt) }
                try self.require(sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, db: db)
                self.bindText(stmt, 1, threshold)

                while sqlite3_step(stmt) == SQLITE_ROW {
                    results.append(
                        OverdueItem(
                            mediaId: self.columnText(stmt, 0) ?? "",
                            mediaType: self.columnText(stmt, 1) ?? "",
                            mediaTitle: self.columnText(stmt, 2) ?? "—",
                            borrowerName: "\(self.columnText(stmt, 3) ?? "") \(self.columnText(stmt, 4) ?? "")".trimmingCharacters(in: .whitespaces),
                            checkoutDate: self.columnText(stmt, 5) ?? ""
                        )
                    )
                }
            }

            DispatchQueue.main.async {
                self.overdueItems = results
                self.isLoadingReport = false
            }
        } onError: { error in
            self.errorMessage = error.localizedDescription
            self.isLoadingReport = false
        }
    }

    func fetchMostPopular() {
        isLoadingReport = true
        runAsync {
            func topItem(db: OpaquePointer?, sql: String) throws -> PopularItem? {
                var stmt: OpaquePointer?
                defer { sqlite3_finalize(stmt) }
                try self.require(sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, db: db)
                guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
                return PopularItem(
                    id: self.columnText(stmt, 0) ?? UUID().uuidString,
                    title: self.columnText(stmt, 1) ?? "Untitled",
                    subtitle: self.columnText(stmt, 2) ?? "",
                    imageUrl: self.columnText(stmt, 3),
                    checkoutCount: self.columnInt(stmt, 4) ?? 0
                )
            }

            var report = MostPopularReport(book: nil, game: nil, movie: nil)
            try self.withDatabase { db in
                report = MostPopularReport(
                    book: try topItem(
                        db: db,
                        sql: """
                        SELECT b.id, b.title, b.author, b.image_url, COUNT(ch.id)
                        FROM books b
                        LEFT JOIN checkout_history ch ON ch.media_id = b.id AND ch.media_type = 'books'
                        GROUP BY b.id
                        ORDER BY COUNT(ch.id) DESC, b.title ASC
                        LIMIT 1
                        """
                    ),
                    game: try topItem(
                        db: db,
                        sql: """
                        SELECT vg.id, vg.title, vg.game_system, vg.image_url, COUNT(ch.id)
                        FROM video_games vg
                        LEFT JOIN checkout_history ch ON ch.media_id = vg.id AND ch.media_type = 'video_games'
                        GROUP BY vg.id
                        ORDER BY COUNT(ch.id) DESC, vg.title ASC
                        LIMIT 1
                        """
                    ),
                    movie: try topItem(
                        db: db,
                        sql: """
                        SELECT mv.id, mv.title, mv.director, mv.image_url, COUNT(ch.id)
                        FROM movies mv
                        LEFT JOIN checkout_history ch ON ch.media_id = mv.id AND ch.media_type = 'movies'
                        GROUP BY mv.id
                        ORDER BY COUNT(ch.id) DESC, mv.title ASC
                        LIMIT 1
                        """
                    )
                )
            }

            DispatchQueue.main.async {
                self.mostPopular = report
                self.isLoadingReport = false
            }
        } onError: { error in
            self.errorMessage = error.localizedDescription
            self.isLoadingReport = false
        }
    }

    // MARK: - Diagnostics
    func fetchDiagnosticsStats() {
        isLoadingDiagnostics = true
        runAsync {
            var stats = DiagnosticsStats(totalBooks: 0, totalGames: 0, totalMovies: 0, totalBorrowers: 0, itemsCheckedOut: 0)
            try self.withDatabase { db in
                stats = DiagnosticsStats(
                    totalBooks: try self.scalarInt(db, sql: "SELECT COUNT(*) FROM books"),
                    totalGames: try self.scalarInt(db, sql: "SELECT COUNT(*) FROM video_games"),
                    totalMovies: try self.scalarInt(db, sql: "SELECT COUNT(*) FROM movies"),
                    totalBorrowers: try self.scalarInt(db, sql: "SELECT COUNT(*) FROM borrowers"),
                    itemsCheckedOut: try self.scalarInt(db, sql: "SELECT COUNT(*) FROM checkout_history WHERE status = 'checked_out'")
                )
            }

            DispatchQueue.main.async {
                self.diagnosticsStats = stats
                self.isLoadingDiagnostics = false
            }
        } onError: { error in
            self.errorMessage = error.localizedDescription
            self.isLoadingDiagnostics = false
        }
    }

    func checkDatabaseIntegrity() {
        isCheckingIntegrity = true
        dbHealthy = nil

        runAsync {
            var issues = 0
            try self.withDatabase { db in
                let requiredTables = ["books", "video_games", "movies", "borrowers", "checkout_history"]
                for table in requiredTables {
                    let count = try self.scalarInt(db, sql: "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='\(table)'")
                    if count == 0 { issues += 1 }
                }

                issues += try self.scalarInt(db, sql: "SELECT COUNT(*) FROM checkout_history WHERE borrower_id NOT IN (SELECT id FROM borrowers)")
                issues += try self.scalarInt(db, sql: "SELECT COUNT(*) FROM checkout_history WHERE status NOT IN ('checked_out', 'returned')")
                issues += try self.scalarInt(db, sql: "SELECT COUNT(*) FROM books WHERE title IS NULL OR title = ''")
                issues += try self.scalarInt(db, sql: "SELECT COUNT(*) FROM borrowers WHERE first_name IS NULL OR first_name = '' OR last_name IS NULL OR last_name = ''")
            }

            DispatchQueue.main.async {
                self.dbHealthy = (issues == 0)
                self.isCheckingIntegrity = false
            }
        } onError: { error in
            self.errorMessage = error.localizedDescription
            self.isCheckingIntegrity = false
        }
    }

    func repairDatabase(completion: @escaping (Bool) -> Void) {
        isRepairing = true
        lastRepairSuccess = nil

        runAsync {
            try self.withDatabase { db in
                try self.execute(db, sql: "DELETE FROM checkout_history WHERE borrower_id NOT IN (SELECT id FROM borrowers)")
                try self.execute(db, sql: "UPDATE checkout_history SET status = 'returned' WHERE status NOT IN ('checked_out', 'returned')")
                try self.execute(db, sql: "UPDATE books SET title = '[Unknown Title]' WHERE title IS NULL OR title = ''")
                try self.execute(db, sql: "UPDATE borrowers SET first_name = '[Unknown]' WHERE first_name IS NULL OR first_name = ''")
                try self.execute(db, sql: "UPDATE borrowers SET last_name = '[Unknown]' WHERE last_name IS NULL OR last_name = ''")
            }

            DispatchQueue.main.async {
                self.lastRepairSuccess = true
                self.isRepairing = false
                completion(true)
            }
        } onError: { error in
            self.errorMessage = error.localizedDescription
            self.lastRepairSuccess = false
            self.isRepairing = false
            completion(false)
        }
    }

    // MARK: - SQLite Helpers
    private func runAsync(_ work: @escaping () throws -> Void, onError: @escaping (Error) -> Void) {
        dbQueue.async {
            do {
                try work()
            } catch {
                DispatchQueue.main.async {
                    onError(error)
                }
            }
        }
    }

    private func withDatabase(_ work: (OpaquePointer?) throws -> Void) throws {
        let path = try resolveDatabasePath()
        var db: OpaquePointer?
        guard sqlite3_open(path, &db) == SQLITE_OK else {
            defer { if db != nil { sqlite3_close(db) } }
            throw databaseError(db)
        }
        defer { sqlite3_close(db) }
        try work(db)
    }

    private func execute(_ db: OpaquePointer?, sql: String, bind: ((OpaquePointer?) -> Void)? = nil) throws {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        try require(sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, db: db)
        bind?(stmt)
        try require(sqlite3_step(stmt) == SQLITE_DONE, db: db)
    }

    private func scalarInt(_ db: OpaquePointer?, sql: String) throws -> Int {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        try require(sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, db: db)
        guard sqlite3_step(stmt) == SQLITE_ROW else { return 0 }
        return Int(sqlite3_column_int(stmt, 0))
    }

    private func countAndOwned(db: OpaquePointer?, table: String) throws -> (total: Int, owned: Int) {
        let sql = "SELECT COUNT(*), SUM(CASE WHEN status = 'owned' THEN 1 ELSE 0 END) FROM \(table)"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        try require(sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, db: db)
        guard sqlite3_step(stmt) == SQLITE_ROW else { return (0, 0) }
        let total = Int(sqlite3_column_int(stmt, 0))
        let owned = Int(sqlite3_column_int(stmt, 1))
        return (total, owned)
    }

    private func columnText(_ stmt: OpaquePointer?, _ index: Int32) -> String? {
        guard sqlite3_column_type(stmt, index) != SQLITE_NULL,
              let cString = sqlite3_column_text(stmt, index) else {
            return nil
        }
        return String(cString: cString)
    }

    private func columnInt(_ stmt: OpaquePointer?, _ index: Int32) -> Int? {
        guard sqlite3_column_type(stmt, index) != SQLITE_NULL else { return nil }
        return Int(sqlite3_column_int(stmt, index))
    }

    private func bindText(_ stmt: OpaquePointer?, _ index: Int32, _ value: String) {
        sqlite3_bind_text(stmt, index, value, -1, sqliteTransient)
    }

    private func bindOptionalText(_ stmt: OpaquePointer?, _ index: Int32, _ value: String?) {
        if let value {
            bindText(stmt, index, value)
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    private func bindOptionalInt(_ stmt: OpaquePointer?, _ index: Int32, _ value: Int?) {
        if let value {
            sqlite3_bind_int(stmt, index, Int32(value))
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    private func generateMediaID(prefix: String, digits: Int, table: String, db: OpaquePointer?) throws -> String {
        let sql = "SELECT id FROM \(table) WHERE id LIKE ? ORDER BY id DESC LIMIT 1"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        try require(sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, db: db)
        bindText(stmt, 1, "\(prefix)%")

        var nextNumber = 1
        if sqlite3_step(stmt) == SQLITE_ROW, let lastID = columnText(stmt, 0), lastID.hasPrefix(prefix) {
            let suffix = String(lastID.dropFirst(prefix.count))
            if let value = Int(suffix) {
                nextNumber = value + 1
            }
        }

        return prefix + String(format: "%0*d", digits, nextNumber)
    }

    private func generateBorrowerID(db: OpaquePointer?) throws -> String {
        return try generateMediaID(prefix: "21972", digits: 9, table: "borrowers", db: db)
    }

    private func require(_ condition: Bool, db: OpaquePointer? = nil) throws {
        if !condition {
            throw databaseError(db)
        }
    }

    private func databaseError(_ db: OpaquePointer?) -> NSError {
        let message: String
        if let db, let cMessage = sqlite3_errmsg(db) {
            message = String(cString: cMessage)
        } else {
            message = String(cString: sqlite3_errstr(SQLITE_ERROR))
        }

        return NSError(domain: "MediaInventory.SQLite", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func resolveDatabasePath() throws -> String {
        let fileManager = FileManager.default

        let explicitPath = ProcessInfo.processInfo.environment["MEDIA_INVENTORY_DB_PATH"]
            ?? UserDefaults.standard.string(forKey: "MediaInventoryDatabasePath")
        if let explicitPath, !explicitPath.isEmpty {
            return explicitPath
        }

        let projectRoot = ProcessInfo.processInfo.environment["MEDIA_INVENTORY_PROJECT_ROOT"]
            ?? UserDefaults.standard.string(forKey: "MediaInventoryProjectPath")

        let cwd = fileManager.currentDirectoryPath
        let home = NSHomeDirectory()

        let candidates = [
            projectRoot.map { "\($0)/media_inventory.db" },
            "\(cwd)/media_inventory.db",
            "\(home)/Media-inventory-system/media_inventory.db",
            "\(home)/Documents/Media-inventory-system/media_inventory.db"
        ].compactMap { $0 }

        if let existing = candidates.first(where: { fileManager.fileExists(atPath: $0) }) {
            UserDefaults.standard.set(existing, forKey: "MediaInventoryDatabasePath")
            return existing
        }

        let appSupport = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let appDir = appSupport.appendingPathComponent("MediaInventory", isDirectory: true)
        try fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        let dbURL = appDir.appendingPathComponent("media_inventory.db")
        UserDefaults.standard.set(dbURL.path, forKey: "MediaInventoryDatabasePath")
        return dbURL.path
    }

    private func ensureDatabaseInitialized() throws {
        try withDatabase { db in
            try execute(db, sql: """
                CREATE TABLE IF NOT EXISTS books (
                    id TEXT PRIMARY KEY,
                    title TEXT NOT NULL,
                    author TEXT,
                    year_published INTEGER,
                    publisher TEXT,
                    fiction_nonfiction TEXT,
                    genre TEXT,
                    description TEXT,
                    image_url TEXT,
                    status TEXT DEFAULT 'owned'
                )
            """)

            try execute(db, sql: """
                CREATE TABLE IF NOT EXISTS video_games (
                    id TEXT PRIMARY KEY,
                    title TEXT NOT NULL,
                    game_system TEXT,
                    genre TEXT,
                    year_released INTEGER,
                    image_url TEXT,
                    status TEXT DEFAULT 'owned'
                )
            """)

            try execute(db, sql: """
                CREATE TABLE IF NOT EXISTS movies (
                    id TEXT PRIMARY KEY,
                    title TEXT NOT NULL,
                    director TEXT,
                    "cast" TEXT,
                    year_released INTEGER,
                    studio TEXT,
                    genre TEXT,
                    format TEXT,
                    image_url TEXT,
                    status TEXT DEFAULT 'owned'
                )
            """)

            try execute(db, sql: """
                CREATE TABLE IF NOT EXISTS borrowers (
                    id TEXT PRIMARY KEY,
                    first_name TEXT NOT NULL,
                    last_name TEXT NOT NULL,
                    address TEXT,
                    phone_number TEXT
                )
            """)

            try execute(db, sql: """
                CREATE TABLE IF NOT EXISTS checkout_history (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    borrower_id TEXT NOT NULL,
                    media_id TEXT NOT NULL,
                    media_type TEXT NOT NULL,
                    checkout_date TEXT NOT NULL,
                    return_date TEXT,
                    status TEXT DEFAULT 'checked_out'
                )
            """)
        }
    }
}
