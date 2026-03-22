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
}

struct BorrowersResponse: Codable {
    let success: Bool
    let borrowers: [Borrower]
}

struct SuccessResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}
