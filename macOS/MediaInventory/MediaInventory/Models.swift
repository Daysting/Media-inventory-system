import Foundation

// MARK: - Book Model
struct Book: Identifiable, Codable {
    let id: String
    let title: String
    let author: String?
    let yearPublished: Int?
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
        title = try container.decode(String.self, forKey: .title)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        yearPublished = try container.decodeIfPresent(Int.self, forKey: .yearPublished)
        publisher = try container.decodeIfPresent(String.self, forKey: .publisher)
        fictionNonfiction = try container.decodeIfPresent(String.self, forKey: .fictionNonfiction)
        genre = try container.decodeIfPresent(String.self, forKey: .genre)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        status = try container.decode(String.self, forKey: .status)
    }
}

// MARK: - Video Game Model
struct Game: Identifiable, Codable {
    let id: String
    let title: String
    let developer: String?
    let platform: String?
    let yearReleased: Int?
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
        case studio
        case genre
        case rating
        case runtimeMinutes = "runtime_minutes"
        case imageUrl = "image_url"
        case status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.decodeFlexibleID(forKey: .id)
        title = container.decodeFlexibleString(forKey: .title, default: "Untitled")
        director = container.decodeFlexibleOptionalString(forKey: .director)
        cast = container.decodeFlexibleOptionalString(forKey: .cast)
        yearReleased = container.decodeFlexibleOptionalInt(forKey: .yearReleased)
        studio = container.decodeFlexibleOptionalString(forKey: .studio)
        genre = container.decodeFlexibleOptionalString(forKey: .genre)
        rating = container.decodeFlexibleOptionalString(forKey: .rating)
        runtimeMinutes = container.decodeFlexibleOptionalInt(forKey: .runtimeMinutes)
        imageUrl = container.decodeFlexibleOptionalString(forKey: .imageUrl)
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
           let stringValue,
           let intValue = Int(stringValue.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return intValue
        }

        return nil
    }
}
