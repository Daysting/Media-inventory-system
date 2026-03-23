import Foundation
import Combine

class APIClient: ObservableObject {
    static let apiBaseURLDefaultsKey = "MediaInventoryAPIBaseURL"
    static let preferredPorts = [5000, 5001, 5002]
    static let defaultBaseURL = baseURL(for: preferredPorts[0])
    static let backendValidationPath = "/diagnostics"

    static func baseURL(for port: Int) -> String {
        "http://127.0.0.1:\(port)/api"
    }

    static var currentBaseURL: String {
        UserDefaults.standard.string(forKey: apiBaseURLDefaultsKey) ?? defaultBaseURL
    }

    static var candidateBaseURLs: [String] {
        var urls: [String] = []

        if let stored = UserDefaults.standard.string(forKey: apiBaseURLDefaultsKey) {
            urls.append(stored)
        }

        urls.append(contentsOf: preferredPorts.map(baseURL(for:)))

        return Array(NSOrderedSet(array: urls)) as? [String] ?? urls
    }

    static func persistBaseURL(_ baseURL: String) {
        UserDefaults.standard.set(baseURL, forKey: apiBaseURLDefaultsKey)
    }

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
    
    private var baseURL: String {
        APIClient.currentBaseURL
    }
    private let session = URLSession.shared
    
    // MARK: - Books
    func fetchBooks() {
        isLoading = true
        fetch(endpoint: "/books", responseType: BooksResponse.self) { [weak self] result in
            switch result {
            case .success(let response):
                self?.books = response.books
                self?.isLoading = false
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
                self?.isLoading = false
            }
        }
    }
    
    func addBook(title: String, author: String?, yearPublished: Int?, publisher: String?, 
                 fictionNonfiction: String?, genre: String?, description: String?, imageUrl: String?) {
        let parameters: [String: Any?] = [
            "title": title,
            "author": author,
            "year_published": yearPublished,
            "publisher": publisher,
            "fiction_nonfiction": fictionNonfiction,
            "genre": genre,
            "description": description,
            "image_url": imageUrl
        ]
        
        post(endpoint: "/books", parameters: parameters) { [weak self] result in
            switch result {
            case .success(_):
                self?.fetchBooks()
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteBook(id: String) {
        delete(endpoint: "/books/\(id)") { [weak self] result in
            switch result {
            case .success(_):
                self?.fetchBooks()
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Games
    func fetchGames() {
        isLoading = true
        fetch(endpoint: "/video_games", responseType: GamesResponse.self) { [weak self] result in
            switch result {
            case .success(let response):
                self?.games = response.games
                self?.isLoading = false
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
                self?.isLoading = false
            }
        }
    }
    
    func addGame(title: String, developer: String?, platform: String?, yearReleased: Int?,
                 genre: String?, rating: String?, imageUrl: String?) {
        let parameters: [String: Any?] = [
            "title": title,
            "developer": developer,
            "platform": platform,
            "year_released": yearReleased,
            "genre": genre,
            "rating": rating,
            "image_url": imageUrl
        ]
        
        post(endpoint: "/video_games", parameters: parameters) { [weak self] result in
            switch result {
            case .success(_):
                self?.fetchGames()
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteGame(id: String) {
        delete(endpoint: "/video_games/\(id)") { [weak self] result in
            switch result {
            case .success(_):
                self?.fetchGames()
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Movies
    func fetchMovies() {
        isLoading = true
        requestData(endpoint: "/movies") { [weak self] result in
            guard let self else { return }

            switch result {
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            case .success(let validData):
                do {
                    let parsedMovies = try self.parseMoviesResponse(data: validData)
                    self.movies = parsedMovies
                    self.isLoading = false
                } catch {
                    let payload = String(data: validData, encoding: .utf8) ?? "<non-utf8 payload>"
                    self.errorMessage = "Failed to decode /movies: \(error.localizedDescription). Payload: \(String(payload.prefix(500)))"
                    self.isLoading = false
                }
            }
        }
    }
    
    func addMovie(title: String, director: String?, yearReleased: Int?, genre: String?,
                  rating: String?, runtimeMinutes: Int?, imageUrl: String?) {
        let parameters: [String: Any?] = [
            "title": title,
            "director": director,
            "year_released": yearReleased,
            "genre": genre,
            "rating": rating,
            "runtime_minutes": runtimeMinutes,
            "image_url": imageUrl
        ]
        
        post(endpoint: "/movies", parameters: parameters) { [weak self] result in
            switch result {
            case .success(_):
                self?.fetchMovies()
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteMovie(id: String) {
        delete(endpoint: "/movies/\(id)") { [weak self] result in
            switch result {
            case .success(_):
                self?.fetchMovies()
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Borrowers
    func fetchBorrowers() {
        isLoading = true
        requestData(endpoint: "/borrowers") { [weak self] result in
            guard let self else { return }

            switch result {
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            case .success(let validData):
                do {
                    let parsedBorrowers = try self.parseBorrowersResponse(data: validData)
                    self.borrowers = parsedBorrowers
                    self.isLoading = false
                } catch {
                    let payload = String(data: validData, encoding: .utf8) ?? "<non-utf8 payload>"
                    self.errorMessage = "Failed to decode /borrowers: \(error.localizedDescription). Payload: \(String(payload.prefix(500)))"
                    self.isLoading = false
                }
            }
        }
    }
    
    func addBorrower(firstName: String, lastName: String, address: String?, phoneNumber: String?, email: String?) {
        let parameters: [String: Any?] = [
            "first_name": firstName,
            "last_name": lastName,
            "address": address,
            "phone_number": phoneNumber,
            "email": email
        ]
        
        post(endpoint: "/borrowers", parameters: parameters) { [weak self] result in
            switch result {
            case .success(_):
                self?.fetchBorrowers()
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteBorrower(id: String) {
        delete(endpoint: "/borrowers/\(id)") { [weak self] result in
            switch result {
            case .success(_):
                self?.fetchBorrowers()
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - HTTP Methods
    private func fetch<T: Decodable>(endpoint: String, responseType: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        requestData(endpoint: endpoint) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let validData):
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: validData)
                    completion(.success(decoded))
                } catch {
                    let payload = String(data: validData, encoding: .utf8) ?? "<non-utf8 payload>"
                    let snippet = String(payload.prefix(500))
                    let detailedError = NSError(
                        domain: "APIClient.Decoding",
                        code: 1001,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Failed to decode \(endpoint): \(error.localizedDescription)\nPayload: \(snippet)"
                        ]
                    )
                    completion(.failure(detailedError))
                }
            }
        }
    }
    
    private func post(endpoint: String, parameters: [String: Any?], completion: @escaping (Result<SuccessResponse, Error>) -> Void) {
        requestData(endpoint: endpoint, method: "POST", parameters: parameters) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let validData):
                do {
                    let decoded = try JSONDecoder().decode(SuccessResponse.self, from: validData)
                    completion(.success(decoded))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func delete(endpoint: String, completion: @escaping (Result<SuccessResponse, Error>) -> Void) {
        requestData(endpoint: endpoint, method: "DELETE") { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let validData):
                do {
                    let decoded = try JSONDecoder().decode(SuccessResponse.self, from: validData)
                    completion(.success(decoded))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    private func requestData(
        endpoint: String,
        method: String = "GET",
        parameters: [String: Any?]? = nil,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        let candidateBaseURLs = prioritizedCandidateBaseURLs()
        attemptRequest(
            endpoint: endpoint,
            method: method,
            parameters: parameters,
            candidateBaseURLs: candidateBaseURLs,
            index: 0,
            completion: completion
        )
    }

    private func attemptRequest(
        endpoint: String,
        method: String,
        parameters: [String: Any?]?,
        candidateBaseURLs: [String],
        index: Int,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        guard index < candidateBaseURLs.count else {
            completion(.failure(URLError(.cannotConnectToHost)))
            return
        }

        let candidateBaseURL = candidateBaseURLs[index]
        guard let url = URL(string: candidateBaseURL + endpoint) else {
            attemptRequest(
                endpoint: endpoint,
                method: method,
                parameters: parameters,
                candidateBaseURLs: candidateBaseURLs,
                index: index + 1,
                completion: completion
            )
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        if let parameters {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                let filteredParams = parameters.compactMapValues { $0 }
                request.httpBody = try JSONSerialization.data(withJSONObject: filteredParams)
            } catch {
                completion(.failure(error))
                return
            }
        }

        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                switch self.validatedResponseData(data: data, response: response, error: error, endpoint: endpoint) {
                case .success(let validData):
                    APIClient.persistBaseURL(candidateBaseURL)
                    completion(.success(validData))
                case .failure(let validationError):
                    if self.shouldRetryWithAlternateBaseURL(
                        response: response,
                        data: data,
                        error: error,
                        candidateBaseURLs: candidateBaseURLs,
                        index: index
                    ) {
                        self.attemptRequest(
                            endpoint: endpoint,
                            method: method,
                            parameters: parameters,
                            candidateBaseURLs: candidateBaseURLs,
                            index: index + 1,
                            completion: completion
                        )
                        return
                    }

                    completion(.failure(validationError))
                }
            }
        }.resume()
    }

    private func prioritizedCandidateBaseURLs() -> [String] {
        let preferred = [APIClient.currentBaseURL] + APIClient.candidateBaseURLs
        return Array(NSOrderedSet(array: preferred)) as? [String] ?? preferred
    }

    private func shouldRetryWithAlternateBaseURL(
        response: URLResponse?,
        data: Data?,
        error: Error?,
        candidateBaseURLs: [String],
        index: Int
    ) -> Bool {
        guard index + 1 < candidateBaseURLs.count else {
            return false
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .badServerResponse,
                 .cannotConnectToHost,
                 .cannotFindHost,
                 .dnsLookupFailed,
                 .networkConnectionLost,
                 .notConnectedToInternet,
                 .timedOut:
                return true
            default:
                break
            }
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            return true
        }

        let looksLikeBackendPayload = responseLooksLikeBackendPayload(data)

        if httpResponse.statusCode == 403 {
            return true
        }

        return !looksLikeBackendPayload
    }

    private func responseLooksLikeBackendPayload(_ data: Data?) -> Bool {
        guard let data, !data.isEmpty else {
            return false
        }

        guard let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let root = jsonObject as? [String: Any] else {
            return false
        }

        let knownKeys = ["success", "books", "games", "movies", "borrowers", "history", "stats", "barcodes"]
        return knownKeys.contains { root[$0] != nil }
    }

    private func validatedResponseData(data: Data?, response: URLResponse?, error: Error?, endpoint: String) -> Result<Data, Error> {
        if let error {
            return .failure(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(URLError(.badServerResponse))
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let payload = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<empty payload>"
            let snippet = String(payload.prefix(500))
            let httpError = NSError(
                domain: "APIClient.HTTP",
                code: httpResponse.statusCode,
                userInfo: [
                    NSLocalizedDescriptionKey: "Request to \(endpoint) failed with HTTP \(httpResponse.statusCode). Payload: \(snippet)"
                ]
            )
            return .failure(httpError)
        }

        guard let data else {
            return .failure(URLError(.zeroByteResource))
        }

        return .success(data)
    }

    private func parseBorrowersResponse(data: Data) throws -> [Borrower] {
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        guard let root = jsonObject as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        let rawBorrowers = root["borrowers"] as? [[String: Any]] ?? []

        return rawBorrowers.map { item in
            let id = stringValue(item["id"]) ?? UUID().uuidString
            let firstName = stringValue(item["first_name"]) ?? "Unknown"
            let lastName = stringValue(item["last_name"]) ?? "Borrower"
            let address = stringValue(item["address"])
            let phoneNumber = stringValue(item["phone_number"])
            let email = stringValue(item["email"])

            return Borrower(
                id: id,
                firstName: firstName,
                lastName: lastName,
                address: address,
                phoneNumber: phoneNumber,
                email: email
            )
        }
    }

    private func parseMoviesResponse(data: Data) throws -> [Movie] {
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        guard let root = jsonObject as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        let rawMovies = root["movies"] as? [[String: Any]] ?? []

        return rawMovies.map { item in
            let id = stringValue(item["id"]) ?? UUID().uuidString
            let title = stringValue(item["title"]) ?? "Untitled"
            let director = stringValue(item["director"])
            let cast = stringValue(item["cast"])
            let yearReleased = intValue(item["year_released"])
            let studio = stringValue(item["studio"])
            let genre = stringValue(item["genre"])
            let rating = stringValue(item["rating"]) ?? stringValue(item["format"])
            let runtimeMinutes = intValue(item["runtime_minutes"])
            let imageUrl = stringValue(item["image_url"])
            let status = stringValue(item["status"]) ?? "owned"

            return Movie(
                id: id,
                title: title,
                director: director,
                cast: cast,
                yearReleased: yearReleased,
                studio: studio,
                genre: genre,
                rating: rating,
                runtimeMinutes: runtimeMinutes,
                imageUrl: imageUrl,
                status: status
            )
        }
    }

    private func stringValue(_ value: Any?) -> String? {
        guard let value else { return nil }
        if value is NSNull { return nil }
        if let string = value as? String { return string }
        if let int = value as? Int { return String(int) }
        if let double = value as? Double { return String(double) }
        if let bool = value as? Bool { return String(bool) }
        return nil
    }

    private func intValue(_ value: Any?) -> Int? {
        guard let value else { return nil }
        if value is NSNull { return nil }
        if let int = value as? Int { return int }
        if let double = value as? Double { return Int(double) }
        if let string = value as? String {
            return Int(string.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    // MARK: - Reports

    func fetchInventorySummary() {
        isLoadingReport = true
        requestData(endpoint: "/reports/inventory-summary") { [weak self] result in
            guard let self else { return }
            self.isLoadingReport = false
            switch result {
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            case .success(let data):
                do { self.inventorySummary = try self.parseInventorySummary(data: data) }
                catch { self.errorMessage = "Summary decode error: \(error.localizedDescription)" }
            }
        }
    }

    func fetchBorrowerActivity() {
        isLoadingReport = true
        requestData(endpoint: "/reports/borrower-activity") { [weak self] result in
            guard let self else { return }
            self.isLoadingReport = false
            switch result {
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            case .success(let data):
                do { self.borrowerActivity = try self.parseBorrowerActivity(data: data) }
                catch { self.errorMessage = "Borrower activity decode error: \(error.localizedDescription)" }
            }
        }
    }

    func fetchCheckoutHistoryReport() {
        isLoadingReport = true
        requestData(endpoint: "/reports/checkout-history") { [weak self] result in
            guard let self else { return }
            self.isLoadingReport = false
            switch result {
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            case .success(let data):
                do { self.checkoutHistoryEntries = try self.parseCheckoutHistory(data: data) }
                catch { self.errorMessage = "Checkout history decode error: \(error.localizedDescription)" }
            }
        }
    }

    func fetchGenreDistribution() {
        isLoadingReport = true
        requestData(endpoint: "/reports/genre-distribution") { [weak self] result in
            guard let self else { return }
            self.isLoadingReport = false
            switch result {
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            case .success(let data):
                do { self.genreDistribution = try self.parseGenreDistribution(data: data) }
                catch { self.errorMessage = "Genre distribution decode error: \(error.localizedDescription)" }
            }
        }
    }

    func fetchOverdueItems() {
        isLoadingReport = true
        requestData(endpoint: "/reports/overdue-items") { [weak self] result in
            guard let self else { return }
            self.isLoadingReport = false
            switch result {
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            case .success(let data):
                do { self.overdueItems = try self.parseOverdueItems(data: data) }
                catch { self.errorMessage = "Overdue items decode error: \(error.localizedDescription)" }
            }
        }
    }

    func fetchMostPopular() {
        isLoadingReport = true
        requestData(endpoint: "/reports/most-popular") { [weak self] result in
            guard let self else { return }
            self.isLoadingReport = false
            switch result {
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            case .success(let data):
                do { self.mostPopular = try self.parseMostPopular(data: data) }
                catch { self.errorMessage = "Most popular decode error: \(error.localizedDescription)" }
            }
        }
    }

    // MARK: - Diagnostics

    func fetchDiagnosticsStats() {
        isLoadingDiagnostics = true
        requestData(endpoint: "/diagnostics") { [weak self] result in
            guard let self else { return }
            self.isLoadingDiagnostics = false
            switch result {
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            case .success(let data):
                do { self.diagnosticsStats = try self.parseDiagnosticsStats(data: data) }
                catch { self.errorMessage = "Diagnostics parse error: \(error.localizedDescription)" }
            }
        }
    }

    func checkDatabaseIntegrity() {
        isCheckingIntegrity = true
        dbHealthy = nil
        requestData(endpoint: "/check-integrity") { [weak self] result in
            guard let self else { return }
            self.isCheckingIntegrity = false
            switch result {
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            case .success(let data):
                let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
                self.dbHealthy = json?["healthy"] as? Bool
            }
        }
    }

    func repairDatabase(completion: @escaping (Bool) -> Void) {
        isRepairing = true
        lastRepairSuccess = nil
        requestData(endpoint: "/repair", method: "POST") { [weak self] result in
            guard let self else { return }
            self.isRepairing = false
            switch result {
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.lastRepairSuccess = false
                completion(false)
            case .success(let data):
                let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
                let ok = json?["success"] as? Bool ?? false
                self.lastRepairSuccess = ok
                completion(ok)
            }
        }
    }



    private func parseInventorySummary(data: Data) throws -> InventorySummaryReport {
        let json = try JSONSerialization.jsonObject(with: data)
        guard let root = json as? [String: Any],
              let summary = root["summary"] as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        func stats(_ key: String) -> InventorySummaryReport.MediaStats {
            let d = summary[key] as? [String: Any] ?? [:]
            return InventorySummaryReport.MediaStats(
                total: intValue(d["total"]) ?? 0,
                owned: intValue(d["owned"]) ?? 0
            )
        }

        let checkouts = summary["checkouts"] as? [String: Any] ?? [:]
        let borrowers = summary["borrowers"] as? [String: Any] ?? [:]

        return InventorySummaryReport(
            books:                stats("books"),
            videoGames:           stats("video_games"),
            movies:               stats("movies"),
            borrowersTotal:       intValue(borrowers["total"]) ?? 0,
            currentlyCheckedOut:  intValue(checkouts["currently_checked_out"]) ?? 0,
            totalCheckoutHistory: intValue(checkouts["total_history"]) ?? 0
        )
    }

    private func parseBorrowerActivity(data: Data) throws -> [BorrowerActivityEntry] {
        let json = try JSONSerialization.jsonObject(with: data)
        guard let root = json as? [String: Any],
              let items = root["borrowers"] as? [[String: Any]] else {
            throw URLError(.cannotParseResponse)
        }
        return items.map { item in
            BorrowerActivityEntry(
                id:                   stringValue(item["id"]) ?? UUID().uuidString,
                name:                 stringValue(item["name"]) ?? "—",
                currentlyCheckedOut:  intValue(item["currently_checked_out"]) ?? 0,
                totalReturned:        intValue(item["total_returned"]) ?? 0,
                lastActivity:         stringValue(item["last_activity"]) ?? ""
            )
        }
    }

    private func parseCheckoutHistory(data: Data) throws -> [CheckoutHistoryEntry] {
        let json = try JSONSerialization.jsonObject(with: data)
        guard let root = json as? [String: Any],
              let items = root["history"] as? [[String: Any]] else {
            throw URLError(.cannotParseResponse)
        }
        return items.map { item in
            CheckoutHistoryEntry(
                id:           stringValue(item["id"]) ?? UUID().uuidString,
                borrowerName: stringValue(item["borrower_name"]) ?? "—",
                mediaTitle:   stringValue(item["media_title"]) ?? "—",
                mediaType:    stringValue(item["media_type"]) ?? "",
                checkoutDate: stringValue(item["checkout_date"]) ?? "",
                returnDate:   stringValue(item["return_date"]),
                status:       stringValue(item["status"]) ?? "returned"
            )
        }
    }

    private func parseGenreDistribution(data: Data) throws -> GenreDistributionReport {
        let json = try JSONSerialization.jsonObject(with: data)
        guard let root = json as? [String: Any],
              let genres = root["genres"] as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        func parseList(_ key: String) -> [GenreCount] {
            let items = genres[key] as? [[String: Any]] ?? []
            return items.compactMap { item in
                guard let name = stringValue(item["genre"]),
                      let count = intValue(item["count"]) else { return nil }
                return GenreCount(name: name, count: count)
            }
        }

        return GenreDistributionReport(
            books:      parseList("books"),
            videoGames: parseList("video_games"),
            movies:     parseList("movies")
        )
    }

    private func parseOverdueItems(data: Data) throws -> [OverdueItem] {
        let json = try JSONSerialization.jsonObject(with: data)
        guard let root = json as? [String: Any],
              let items = root["overdue"] as? [[String: Any]] else {
            throw URLError(.cannotParseResponse)
        }
        return items.map { item in
            OverdueItem(
                mediaId:      stringValue(item["media_id"]) ?? "",
                mediaType:    stringValue(item["media_type"]) ?? "",
                mediaTitle:   stringValue(item["media_title"]) ?? "—",
                borrowerName: stringValue(item["borrower_name"]) ?? "—",
                checkoutDate: stringValue(item["checkout_date"]) ?? ""
            )
        }
    }

    private func parseMostPopular(data: Data) throws -> MostPopularReport {
        let json = try JSONSerialization.jsonObject(with: data)
        guard let root = json as? [String: Any],
              let popular = root["popular"] as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        func parseItem(_ key: String) -> PopularItem? {
            guard let item = popular[key] as? [String: Any],
                  let title = stringValue(item["title"]) else { return nil }
            return PopularItem(
                id:            stringValue(item["id"]) ?? UUID().uuidString,
                title:         title,
                subtitle:      stringValue(item["subtitle"]) ?? "",
                imageUrl:      stringValue(item["image_url"]),
                checkoutCount: intValue(item["checkout_count"]) ?? 0
            )
        }

        return MostPopularReport(
            book:  parseItem("book"),
            game:  parseItem("game"),
            movie: parseItem("movie")
        )
    }

    private func parseDiagnosticsStats(data: Data) throws -> DiagnosticsStats {
        let json = try JSONSerialization.jsonObject(with: data)
        guard let root = json as? [String: Any],
              let stats = root["stats"] as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        return DiagnosticsStats(
            totalBooks:       intValue(stats["total_books"]) ?? 0,
            totalGames:       intValue(stats["total_games"]) ?? 0,
            totalMovies:      intValue(stats["total_movies"]) ?? 0,
            totalBorrowers:   intValue(stats["total_borrowers"]) ?? 0,
            itemsCheckedOut:  intValue(stats["items_checked_out"]) ?? 0
        )
    }
}
