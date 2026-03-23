import Foundation

// MARK: - Book Model
struct Book: Identifiable, Codable {
    let id: String
    let title: String
    let author: String?
    let yearPublished: Int?
    let cost: Double?
    let publisher: String?
    let fictionNonfiction: String?
    let genre: String?
    let description: String?
    let imageUrl: String?
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case author
        case yearPublished = "year_published"
        case cost
        case publisher
        case fictionNonfiction = "fiction_nonfiction"
        case genre
        case description
        case imageUrl = "image_url"
        case status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeFlexibleID(forKey: .id)
        title = container.decodeFlexibleString(forKey: .title, default: "Untitled")
        author = container.decodeFlexibleOptionalString(forKey: .author)
        yearPublished = container.decodeFlexibleOptionalInt(forKey: .yearPublished)
        cost = container.decodeFlexibleOptionalDouble(forKey: .cost)
        publisher = container.decodeFlexibleOptionalString(forKey: .publisher)
        fictionNonfiction = container.decodeFlexibleOptionalString(forKey: .fictionNonfiction)
        genre = container.decodeFlexibleOptionalString(forKey: .genre)
        description = container.decodeFlexibleOptionalString(forKey: .description)
        imageUrl = container.decodeFlexibleOptionalString(forKey: .imageUrl)
        status = container.decodeFlexibleString(forKey: .status, default: "owned")
    }
}

// MARK: - Video Game Model
struct Game: Identifiable, Codable {
    let id: String
    let title: String
    let developer: String?
    let platform: String?
    let yearReleased: Int?
    let cost: Double?
    let genre: String?
    let rating: String?
    let description: String?
    let imageUrl: String?
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case developer
        case platform
        case yearReleased = "year_released"
        case cost
        case genre
        case rating
        case description
        case imageUrl = "image_url"
        case status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeFlexibleID(forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        developer = try container.decodeIfPresent(String.self, forKey: .developer)
        platform = try container.decodeIfPresent(String.self, forKey: .platform)
        yearReleased = try container.decodeIfPresent(Int.self, forKey: .yearReleased)
        cost = container.decodeFlexibleOptionalDouble(forKey: .cost)
        genre = try container.decodeIfPresent(String.self, forKey: .genre)
        rating = try container.decodeIfPresent(String.self, forKey: .rating)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        status = try container.decode(String.self, forKey: .status)
    }
}

// MARK: - Movie Model
struct Movie: Identifiable, Codable {
    let id: String
    let title: String
    let director: String?
    let cast: String?
    let yearReleased: Int?
    let cost: Double?
    let studio: String?
    let genre: String?
    let rating: String?
    let runtimeMinutes: Int?
    let imageUrl: String?
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case director
        case cast
        case yearReleased = "year_released"
        case cost
        case studio
        case genre
        case rating
        case runtimeMinutes = "runtime_minutes"
        case imageUrl = "image_url"
        case status
    }

    init(id: String, title: String, director: String?, cast: String?, yearReleased: Int?, cost: Double?, studio: String?, genre: String?, rating: String?, runtimeMinutes: Int?, imageUrl: String?, status: String) {
        self.id = id
        self.title = title
        self.director = director
        self.cast = cast
        self.yearReleased = yearReleased
        self.cost = cost
        self.studio = studio
        self.genre = genre
        self.rating = rating
        self.runtimeMinutes = runtimeMinutes
        self.imageUrl = imageUrl
        self.status = status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeFlexibleID(forKey: .id)
        title = container.decodeFlexibleString(forKey: .title, default: "Untitled")
        director = container.decodeFlexibleOptionalString(forKey: .director)
        cast = container.decodeFlexibleOptionalString(forKey: .cast)
        yearReleased = container.decodeFlexibleOptionalInt(forKey: .yearReleased)
        cost = container.decodeFlexibleOptionalDouble(forKey: .cost)
        studio = container.decodeFlexibleOptionalString(forKey: .studio)
        genre = container.decodeFlexibleOptionalString(forKey: .genre)
        rating = container.decodeFlexibleOptionalString(forKey: .rating)
        runtimeMinutes = container.decodeFlexibleOptionalInt(forKey: .runtimeMinutes)
        imageUrl = container.decodeFlexibleOptionalString(forKey: .imageUrl)
        status = container.decodeFlexibleString(forKey: .status, default: "owned")
    }
}

// MARK: - Electronics Model
struct Electronic: Identifiable, Codable {
    let id: String
    let title: String
    let serialNumber: String?
    let cost: Double?
    let description: String?
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case serialNumber = "serial_number"
        case cost
        case description
        case status
    }

    init(id: String, title: String, serialNumber: String?, cost: Double?, description: String?, status: String) {
        self.id = id
        self.title = title
        self.serialNumber = serialNumber
        self.cost = cost
        self.description = description
        self.status = status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeFlexibleID(forKey: .id)
        title = container.decodeFlexibleString(forKey: .title, default: "Untitled")
        serialNumber = container.decodeFlexibleOptionalString(forKey: .serialNumber)
        cost = container.decodeFlexibleOptionalDouble(forKey: .cost)
        description = container.decodeFlexibleOptionalString(forKey: .description)
        status = container.decodeFlexibleString(forKey: .status, default: "owned")
    }
}

// MARK: - Borrower Model
struct Borrower: Identifiable, Codable {
    let id: String
    let firstName: String
    let lastName: String
    let address: String?
    let phoneNumber: String?
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case address
        case phoneNumber = "phone_number"
        case email
    }

    init(id: String, firstName: String, lastName: String, address: String?, phoneNumber: String?, email: String?) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.address = address
        self.phoneNumber = phoneNumber
        self.email = email
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeFlexibleID(forKey: .id)
        firstName = container.decodeFlexibleString(forKey: .firstName, default: "Unknown")
        lastName = container.decodeFlexibleString(forKey: .lastName, default: "Borrower")
        address = container.decodeFlexibleOptionalString(forKey: .address)
        phoneNumber = container.decodeFlexibleOptionalString(forKey: .phoneNumber)
        email = container.decodeFlexibleOptionalString(forKey: .email)
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

// MARK: - API Response Models
struct BooksResponse: Codable {
    let success: Bool
    let books: [Book]

    enum CodingKeys: String, CodingKey {
        case success
        case books
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = (try? container.decode(Bool.self, forKey: .success)) ?? false
        books = (try? container.decode([Book].self, forKey: .books)) ?? []
    }
}

struct GamesResponse: Codable {
    let success: Bool
    let games: [Game]
}

struct MoviesResponse: Codable {
    let success: Bool
    let movies: [Movie]

    enum CodingKeys: String, CodingKey {
        case success
        case movies
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = (try? container.decode(Bool.self, forKey: .success)) ?? false
        movies = (try? container.decode([Movie].self, forKey: .movies)) ?? []
    }
}

struct ElectronicsResponse: Codable {
    let success: Bool
    let electronics: [Electronic]

    enum CodingKeys: String, CodingKey {
        case success
        case electronics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = (try? container.decode(Bool.self, forKey: .success)) ?? false
        electronics = (try? container.decode([Electronic].self, forKey: .electronics)) ?? []
    }
}

struct BorrowersResponse: Codable {
    let success: Bool
    let borrowers: [Borrower]

    enum CodingKeys: String, CodingKey {
        case success
        case borrowers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = (try? container.decode(Bool.self, forKey: .success)) ?? false
        borrowers = (try? container.decode([Borrower].self, forKey: .borrowers)) ?? []
    }
}

struct SuccessResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}

private extension KeyedDecodingContainer {
    func decodeFlexibleID(forKey key: K) -> String {
        if let stringValue = try? decode(String.self, forKey: key), !stringValue.isEmpty {
            return stringValue
        }

        if let intValue = try? decode(Int.self, forKey: key) {
            return String(intValue)
        }

        if let doubleValue = try? decode(Double.self, forKey: key) {
            return String(Int(doubleValue))
        }

        return UUID().uuidString
    }

    func decodeFlexibleString(forKey key: K, default defaultValue: String = "") -> String {
        if let stringValue = try? decode(String.self, forKey: key), !stringValue.isEmpty {
            return stringValue
        }

        if let intValue = try? decode(Int.self, forKey: key) {
            return String(intValue)
        }

        if let doubleValue = try? decode(Double.self, forKey: key) {
            return String(doubleValue)
        }

        if let boolValue = try? decode(Bool.self, forKey: key) {
            return String(boolValue)
        }

        return defaultValue
    }

    func decodeFlexibleOptionalString(forKey key: K) -> String? {
        guard contains(key) else {
            return nil
        }

        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            return stringValue
        }

        if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return String(intValue)
        }

        if let doubleValue = try? decodeIfPresent(Double.self, forKey: key) {
            return String(doubleValue)
        }

        if let boolValue = try? decodeIfPresent(Bool.self, forKey: key) {
            return String(boolValue)
        }

        return nil
    }

    func decodeFlexibleOptionalInt(forKey key: K) -> Int? {
        guard contains(key) else {
            return nil
        }

        if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }

        if let doubleValue = try? decodeIfPresent(Double.self, forKey: key) {
            return Int(doubleValue)
        }

          if let stringValue = try? decodeIfPresent(String.self, forKey: key),
              let intValue = Int(stringValue.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return intValue
        }

        return nil
    }

    func decodeFlexibleOptionalDouble(forKey key: K) -> Double? {
        guard contains(key) else {
            return nil
        }

        if let doubleValue = try? decodeIfPresent(Double.self, forKey: key) {
            return doubleValue
        }

        if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return Double(intValue)
        }

        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            let normalized = stringValue
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: ",", with: "")
            return Double(normalized)
        }

        return nil
    }
}

extension Double {
    var currencyDisplayText: String {
        Self.currencyFormatter.string(from: NSNumber(value: self)) ?? String(format: "$%.2f", self)
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
}

// MARK: - Report Models

struct InventorySummaryReport {
    struct MediaStats {
        let total: Int
        let owned: Int
    }
    let books: MediaStats
    let videoGames: MediaStats
    let movies: MediaStats
    let electronics: MediaStats
    let borrowersTotal: Int
    let currentlyCheckedOut: Int
    let totalCheckoutHistory: Int
}

struct BorrowerActivityEntry: Identifiable {
    let id: String
    let name: String
    let currentlyCheckedOut: Int
    let totalReturned: Int
    let lastActivity: String
}

struct CheckoutHistoryEntry: Identifiable {
    let id: String
    let mediaId: String
    let borrowerId: String
    let borrowerName: String
    let mediaTitle: String
    let mediaType: String
    let checkoutDate: String
    let returnDate: String?
    let status: String
}

struct GenreDistributionReport {
    let books: [GenreCount]
    let videoGames: [GenreCount]
    let movies: [GenreCount]
}

struct GenreCount: Identifiable {
    var id: String { name }
    let name: String
    let count: Int
}

struct OverdueItem: Identifiable {
    var id: String { mediaId + borrowerName }
    let mediaId: String
    let borrowerId: String
    let mediaType: String
    let mediaTitle: String
    let borrowerName: String
    let checkoutDate: String

    var daysOverdue: Int {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = fmt.date(from: checkoutDate) else { return 0 }
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
    }
}

struct PopularItem {
    let id: String
    let title: String
    let subtitle: String
    let imageUrl: String?
    let checkoutCount: Int
}

struct MostPopularReport {
    let book: PopularItem?
    let game: PopularItem?
    let movie: PopularItem?
}

// MARK: - Diagnostics Models

struct DiagnosticsStats {
    let totalBooks: Int
    let totalGames: Int
    let totalMovies: Int
    let totalElectronics: Int
    let totalBorrowers: Int
    let itemsCheckedOut: Int
}
