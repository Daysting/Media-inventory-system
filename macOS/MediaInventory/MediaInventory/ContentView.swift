import SwiftUI

struct ContentView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var selectedTab: Tab = .dashboard
    
    enum Tab {
        case dashboard, books, games, movies, borrowers, checkout
    }
    
    var body: some View {
        ZStack {
            // Main content
            HStack(spacing: 0) {
                // Sidebar
                VStack(alignment: .leading, spacing: 8) {
                    Text("MAIN")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    
                    NavigationButton(
                        icon: "chart.pie.fill",
                        label: "Dashboard",
                        isSelected: selectedTab == .dashboard,
                        action: { selectedTab = .dashboard }
                    )
                    
                    Text("MEDIA")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    
                    NavigationButton(
                        icon: "book.fill",
                        label: "Books",
                        isSelected: selectedTab == .books,
                        action: { selectedTab = .books }
                    )
                    
                    NavigationButton(
                        icon: "gamecontroller.fill",
                        label: "Video Games",
                        isSelected: selectedTab == .games,
                        action: { selectedTab = .games }
                    )
                    
                    NavigationButton(
                        icon: "film.fill",
                        label: "Movies",
                        isSelected: selectedTab == .movies,
                        action: { selectedTab = .movies }
                    )
                    
                    Text("MANAGEMENT")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    
                    NavigationButton(
                        icon: "person.2.fill",
                        label: "Borrowers",
                        isSelected: selectedTab == .borrowers,
                        action: { selectedTab = .borrowers }
                    )
                    
                    NavigationButton(
                        icon: "arrow.left.arrow.right",
                        label: "Checkout/Return",
                        isSelected: selectedTab == .checkout,
                        action: { selectedTab = .checkout }
                    )
                    
                    Spacer()
                }
                .frame(width: 220)
                .background(Color(nsColor: NSColor.controlBackgroundColor))
                .border(Color.gray.opacity(0.2), width: 1)
                
                // Main content area
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedTab.title)
                                .font(.system(size: 28, weight: .semibold))
                            Text(selectedTab.subtitle)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(20)
                    .background(Color(nsColor: NSColor.controlBackgroundColor))
                    .border(Color.gray.opacity(0.2), width: 1)
                    
                    // Tab content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Group {
                                switch selectedTab {
                                case .dashboard:
                                    DashboardView()
                                case .books:
                                    BooksView()
                                case .games:
                                    GamesView()
                                case .movies:
                                    MoviesView()
                                case .borrowers:
                                    BorrowersView()
                                case .checkout:
                                    CheckoutView()
                                }
                            }
                            .environmentObject(apiClient)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            
            // Error overlay
            if let error = apiClient.errorMessage {
                ErrorAlert(message: error, onDismiss: {
                    apiClient.errorMessage = nil
                })
            }
        }
        .onAppear {
            apiClient.fetchBooks()
            apiClient.fetchGames()
            apiClient.fetchMovies()
            apiClient.fetchBorrowers()
        }
    }
}

// MARK: - Navigation Button
struct NavigationButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 14))
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 8)
    }
}

// MARK: - Error Alert
struct ErrorAlert: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                Text(message)
            }
            .padding(12)
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
            .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - Tab Extensions
extension ContentView.Tab {
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .books: return "Books"
        case .games: return "Video Games"
        case .movies: return "Movies"
        case .borrowers: return "Borrowers"
        case .checkout: return "Checkout & Return"
        }
    }
    
    var subtitle: String {
        switch self {
        case .dashboard: return "Overview of your media inventory"
        case .books: return "Manage your book collection"
        case .games: return "Manage your game collection"
        case .movies: return "Manage your movie collection"
        case .borrowers: return "Manage borrower information"
        case .checkout: return "Manage item checkouts and returns"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(APIClient())
}
