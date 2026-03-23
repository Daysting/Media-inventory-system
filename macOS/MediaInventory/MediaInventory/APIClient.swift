import Foundation
import Combine

class APIClient: ObservableObject {
    @Published var books: [Book] = []
    @Published var games: [Game] = []
    @Published var movies: [Movie] = []
    @Published var borrowers: [Borrower] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showNewBookSheet = false
    
    private let baseURL = "http://localhost:5000/api"
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
        guard let url = URL(string: baseURL + "/movies") else {
            errorMessage = URLError(.badURL).localizedDescription
            isLoading = false
            return
        }

        session.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self else { return }

                if let error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    return
                }

                guard let data else {
                    self.errorMessage = URLError(.zeroByteResource).localizedDescription
                    self.isLoading = false
                    return
                }

                do {
                    let parsedMovies = try self.parseMoviesResponse(data: data)
                    self.movies = parsedMovies
                    self.isLoading = false
                } catch {
                    let payload = String(data: data, encoding: .utf8) ?? "<non-utf8 payload>"
                    self.errorMessage = "Failed to decode /movies: \(error.localizedDescription). Payload: \(String(payload.prefix(500)))"
                    self.isLoading = false
                }
            }
        }.resume()
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
        guard let url = URL(string: baseURL + "/borrowers") else {
            errorMessage = URLError(.badURL).localizedDescription
            isLoading = false
            return
        }

        session.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self else { return }

                if let error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    return
                }

                guard let data else {
                    self.errorMessage = URLError(.zeroByteResource).localizedDescription
                    self.isLoading = false
                    return
                }

                do {
                    let parsedBorrowers = try self.parseBorrowersResponse(data: data)
                    self.borrowers = parsedBorrowers
                    self.isLoading = false
                } catch {
                    let payload = String(data: data, encoding: .utf8) ?? "<non-utf8 payload>"
                    self.errorMessage = "Failed to decode /borrowers: \(error.localizedDescription). Payload: \(String(payload.prefix(500)))"
                    self.isLoading = false
                }
            }
        }.resume()
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
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(URLError(.zeroByteResource)))
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decoded))
                } catch {
                    let payload = String(data: data, encoding: .utf8) ?? "<non-utf8 payload>"
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
        }.resume()
    }
    
    private func post(endpoint: String, parameters: [String: Any?], completion: @escaping (Result<SuccessResponse, Error>) -> Void) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let filteredParams = parameters.compactMapValues { $0 }
            request.httpBody = try JSONSerialization.data(withJSONObject: filteredParams)
        } catch {
            completion(.failure(error))
            return
        }
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(URLError(.zeroByteResource)))
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(SuccessResponse.self, from: data)
                    completion(.success(decoded))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    private func delete(endpoint: String, completion: @escaping (Result<SuccessResponse, Error>) -> Void) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(URLError(.zeroByteResource)))
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(SuccessResponse.self, from: data)
                    completion(.success(decoded))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
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
}
