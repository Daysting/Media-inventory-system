import CoreSpotlight
import Combine

class SearchIndexer {
    private var cancellables = Set<AnyCancellable>()
    
    func indexMedia() {
        let apiClient = APIClient()
        
        // Index Books
        indexBooks(apiClient: apiClient)
        
        // Index Games
        indexGames(apiClient: apiClient)
        
        // Index Movies
        indexMovies(apiClient: apiClient)
        
        // Index Borrowers
        indexBorrowers(apiClient: apiClient)
    }
    
    private func indexBooks(apiClient: APIClient) {
        apiClient.fetchBooks()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            var searchableItems: [CSSearchableItem] = []
            
            for book in apiClient.books {
                let attributes = CSSearchableItemAttributeSet(itemContentType: "com.example.book")
                attributes.title = book.title
                attributes.subtitle = book.author ?? "Unknown Author"
                attributes.contentDescription = book.description ?? book.genre ?? "No description"
                attributes.keywords = [book.genre ?? "", book.fictionNonfiction ?? ""].filter { !$0.isEmpty }
                
                if let imageUrl = book.imageUrl, let url = URL(string: imageUrl) {
                    if let imageData = try? Data(contentsOf: url) {
                        attributes.thumbnailData = imageData
                    }
                }
                
                let item = CSSearchableItem(uniqueIdentifier: "book_\(book.id)", domainIdentifier: "com.mediaInventory.books", attributeSet: attributes)
                searchableItems.append(item)
            }
            
            CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
                if let error = error {
                    print("Error indexing books: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func indexGames(apiClient: APIClient) {
        apiClient.fetchGames()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            var searchableItems: [CSSearchableItem] = []
            
            for game in apiClient.games {
                let attributes = CSSearchableItemAttributeSet(itemContentType: "com.example.game")
                attributes.title = game.title
                attributes.subtitle = game.platform ?? "Unknown Platform"
                attributes.contentDescription = game.description ?? game.genre ?? "No description"
                attributes.keywords = [game.genre ?? "", game.platform ?? ""].filter { !$0.isEmpty }
                
                if let imageUrl = game.imageUrl, let url = URL(string: imageUrl) {
                    if let imageData = try? Data(contentsOf: url) {
                        attributes.thumbnailData = imageData
                    }
                }
                
                let item = CSSearchableItem(uniqueIdentifier: "game_\(game.id)", domainIdentifier: "com.mediaInventory.games", attributeSet: attributes)
                searchableItems.append(item)
            }
            
            CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
                if let error = error {
                    print("Error indexing games: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func indexMovies(apiClient: APIClient) {
        apiClient.fetchMovies()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            var searchableItems: [CSSearchableItem] = []
            
            for movie in apiClient.movies {
                let attributes = CSSearchableItemAttributeSet(itemContentType: "com.example.movie")
                attributes.title = movie.title
                attributes.subtitle = movie.director ?? "Unknown Director"
                attributes.contentDescription = movie.description ?? movie.genre ?? "No description"
                attributes.keywords = [movie.genre ?? "", movie.rating ?? ""].filter { !$0.isEmpty }
                
                if let imageUrl = movie.imageUrl, let url = URL(string: imageUrl) {
                    if let imageData = try? Data(contentsOf: url) {
                        attributes.thumbnailData = imageData
                    }
                }
                
                let item = CSSearchableItem(uniqueIdentifier: "movie_\(movie.id)", domainIdentifier: "com.mediaInventory.movies", attributeSet: attributes)
                searchableItems.append(item)
            }
            
            CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
                if let error = error {
                    print("Error indexing movies: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func indexBorrowers(apiClient: APIClient) {
        apiClient.fetchBorrowers()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            var searchableItems: [CSSearchableItem] = []
            
            for borrower in apiClient.borrowers {
                let attributes = CSSearchableItemAttributeSet(itemContentType: "com.example.borrower")
                attributes.title = borrower.fullName
                attributes.subtitle = borrower.phoneNumber ?? borrower.email ?? "No contact info"
                attributes.contentDescription = borrower.address ?? "No address on file"
                
                let item = CSSearchableItem(uniqueIdentifier: "borrower_\(borrower.id)", domainIdentifier: "com.mediaInventory.borrowers", attributeSet: attributes)
                searchableItems.append(item)
            }
            
            CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
                if let error = error {
                    print("Error indexing borrowers: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func deleteAllIndexes() {
        CSSearchableIndex.default().deleteAllSearchableItems { error in
            if let error = error {
                print("Error deleting indexes: \(error.localizedDescription)")
            }
        }
    }
}
