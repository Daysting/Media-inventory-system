import SwiftUI

struct ContentView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var selectedTab: Tab = .dashboard
    private let errorPanelHeight: CGFloat = 120
    
    enum Tab {
        case dashboard, books, games, movies, borrowers, checkout, reports
    }
    
    var body: some View {
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

                Text("ANALYTICS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                NavigationButton(
                    icon: "chart.bar.fill",
                    label: "Reports",
                    isSelected: selectedTab == .reports,
                    action: { selectedTab = .reports }
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
                                DashboardView(navigate: { tab in selectedTab = tab })
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
                            case .reports:
                                ReportsView()
                            }
                        }
                        .environmentObject(apiClient)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                ErrorPanel(
                    message: apiClient.errorMessage,
                    onDismiss: { apiClient.errorMessage = nil }
                )
                .frame(height: errorPanelHeight)
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

// MARK: - Error Panel
struct ErrorPanel: View {
    let message: String?
    let onDismiss: () -> Void

    var body: some View {
        VStack {
            HStack {
                Label("Errors", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                if message != nil {
                    Button("Clear", action: onDismiss)
                        .buttonStyle(.borderless)
                }
            }

            Divider()

            Group {
                if let message, !message.isEmpty {
                    ScrollView {
                        Text(message)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                } else {
                    Text("No current errors")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(nsColor: NSColor.controlBackgroundColor))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
        }
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
        case .reports: return "Reports"
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
        case .reports: return "Analytics and usage reports"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(APIClient())
}
