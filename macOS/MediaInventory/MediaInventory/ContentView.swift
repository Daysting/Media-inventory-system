import SwiftUI

struct ContentView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var selectedTab: Tab = .dashboard
    private let errorPanelHeight: CGFloat = 120
    private let startupPanelHeight: CGFloat = 130
    @State private var hasBootstrapped = false
    @State private var isBootstrappingConnection = false
    @State private var startupDiagnostics: [String] = []
    
    enum Tab {
        case dashboard, books, games, movies, borrowers, checkout, reports, diagnostics
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

                Text("SYSTEM")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                NavigationButton(
                    icon: "stethoscope",
                    label: "Diagnostics",
                    isSelected: selectedTab == .diagnostics,
                    action: { selectedTab = .diagnostics }
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

                if isBootstrappingConnection {
                    HStack(spacing: 10) {
                        ProgressView()
                            .scaleEffect(0.75)
                        Text("Connecting to local server... retrying once automatically")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.06))
                }

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
                            case .diagnostics:
                                DiagnosticsView()
                            }
                        }
                        .environmentObject(apiClient)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                ErrorPanel(
                    message: visibleErrorMessage,
                    onDismiss: { apiClient.errorMessage = nil }
                )
                .frame(height: errorPanelHeight)

                StartupDiagnosticsPanel(
                    lines: startupDiagnostics,
                    isBootstrapping: isBootstrappingConnection,
                    onClear: { startupDiagnostics.removeAll() }
                )
                .frame(height: startupPanelHeight)
            }
        }
        .onAppear {
            guard !hasBootstrapped else { return }
            hasBootstrapped = true
            bootstrapInitialDataLoad()
        }
        .onReceive(NotificationCenter.default.publisher(for: .backendStartupDiagnostic)) { notification in
            guard let line = notification.userInfo?["message"] as? String else { return }
            startupDiagnostics.append(line)
            if startupDiagnostics.count > 250 {
                startupDiagnostics.removeFirst(startupDiagnostics.count - 250)
            }
        }
    }

    private var visibleErrorMessage: String? {
        guard let message = apiClient.errorMessage else { return nil }
        if isBootstrappingConnection && isLikelyConnectionError(message) {
            return nil
        }
        return message
    }

    private func bootstrapInitialDataLoad() {
        isBootstrappingConnection = true

        func loadAll() {
            apiClient.fetchBooks()
            apiClient.fetchGames()
            apiClient.fetchMovies()
            apiClient.fetchBorrowers()
        }

        loadAll()

        // Retry once after a short delay to absorb backend startup race conditions.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            if let currentError = apiClient.errorMessage,
               isLikelyConnectionError(currentError) {
                apiClient.errorMessage = nil
            }
            loadAll()
        }

        // End bootstrap phase; only then allow connection errors to surface.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            isBootstrappingConnection = false
            if let currentError = apiClient.errorMessage,
               isLikelyConnectionError(currentError) {
                apiClient.errorMessage = "Could not connect to the server."
            }
        }
    }

    private func isLikelyConnectionError(_ message: String) -> Bool {
        let lower = message.lowercased()
        return lower.contains("cannot connect") ||
               lower.contains("not connected") ||
               lower.contains("timed out") ||
               lower.contains("offline") ||
               lower.contains("network") ||
               lower.contains("could not connect")
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

struct StartupDiagnosticsPanel: View {
    let lines: [String]
    let isBootstrapping: Bool
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Startup Diagnostics", systemImage: "terminal")
                    .font(.system(size: 13, weight: .semibold))

                if isBootstrapping {
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }

                Spacer()

                if !lines.isEmpty {
                    Button("Clear", action: onClear)
                        .buttonStyle(.borderless)
                }
            }

            Divider()

            Group {
                if lines.isEmpty {
                    Text("No startup diagnostics yet")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else {
                    ScrollView {
                        Text(lines.joined(separator: "\n"))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
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
        case .diagnostics: return "Diagnostics"
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
        case .diagnostics: return "System health, database integrity and repair"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(APIClient())
}
