import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var apiClient: APIClient
    var navigate: (ContentView.Tab) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            // MARK: Stat cards
            Grid(alignment: .topLeading, horizontalSpacing: 16, verticalSpacing: 16) {
                GridRow {
                    ClickableStatCard(icon: "📚", title: "Books",
                                      value: String(apiClient.books.count)) { navigate(.books) }
                    ClickableStatCard(icon: "🎮", title: "Video Games",
                                      value: String(apiClient.games.count)) { navigate(.games) }
                    ClickableStatCard(icon: "🎬", title: "Movies",
                                      value: String(apiClient.movies.count)) { navigate(.movies) }
                    ClickableStatCard(icon: "👥", title: "Borrowers",
                                      value: String(apiClient.borrowers.count)) { navigate(.borrowers) }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // MARK: Entry lists
            DashboardListSection(title: "Books", systemIcon: "book.fill",
                                 onViewAll: { navigate(.books) }) {
                if apiClient.books.isEmpty {
                    DashboardEmptyRow(message: "No books in collection yet")
                } else {
                    ForEach(apiClient.books) { book in
                        DashboardEntryRow(
                            primary: book.title,
                            secondary: book.author,
                            badge: book.status
                        )
                    }
                }
            }

            DashboardListSection(title: "Video Games", systemIcon: "gamecontroller.fill",
                                 onViewAll: { navigate(.games) }) {
                if apiClient.games.isEmpty {
                    DashboardEmptyRow(message: "No games in collection yet")
                } else {
                    ForEach(apiClient.games) { game in
                        DashboardEntryRow(
                            primary: game.title,
                            secondary: game.platform,
                            badge: game.status
                        )
                    }
                }
            }

            DashboardListSection(title: "Movies", systemIcon: "film.fill",
                                 onViewAll: { navigate(.movies) }) {
                if apiClient.movies.isEmpty {
                    DashboardEmptyRow(message: "No movies in collection yet")
                } else {
                    ForEach(apiClient.movies) { movie in
                        DashboardEntryRow(
                            primary: movie.title,
                            secondary: movie.director,
                            badge: movie.status
                        )
                    }
                }
            }

            DashboardListSection(title: "Borrowers", systemIcon: "person.2.fill",
                                 onViewAll: { navigate(.borrowers) }) {
                if apiClient.borrowers.isEmpty {
                    DashboardEmptyRow(message: "No borrowers registered yet")
                } else {
                    ForEach(apiClient.borrowers) { borrower in
                        DashboardEntryRow(
                            primary: borrower.fullName,
                            secondary: borrower.phoneNumber ?? borrower.email,
                            badge: nil
                        )
                    }
                }
            }

            Spacer(minLength: 20)
        }
    }
}

// MARK: - Clickable Stat Card

struct ClickableStatCard: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: 12) {
                Text(icon)
                    .font(.system(size: 32))
                Text(value)
                    .font(.system(size: 24, weight: .semibold))
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                isHovering
                    ? Color.blue.opacity(0.08)
                    : Color(nsColor: NSColor.controlBackgroundColor)
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(isHovering ? 0.10 : 0.05),
                    radius: isHovering ? 6 : 4)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHovering ? Color.blue.opacity(0.35) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovering = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .help("Go to \(title)")
    }
}

// MARK: - Dashboard List Section

struct DashboardListSection<Content: View>: View {
    let title: String
    let systemIcon: String
    let onViewAll: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Button(action: onViewAll) {
                HStack(spacing: 8) {
                    Image(systemName: systemIcon)
                        .font(.system(size: 13))
                        .foregroundColor(.blue)
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Text("View All")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .buttonStyle(PlainButtonStyle())

            Divider()

            content
        }
        .background(Color(nsColor: NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
}

// MARK: - Dashboard Entry Row

struct DashboardEntryRow: View {
    let primary: String
    let secondary: String?
    let badge: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(primary)
                        .font(.system(size: 13))
                        .lineLimit(1)
                    if let secondary, !secondary.isEmpty {
                        Text(secondary)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if let badge {
                    Badge(badge)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            Divider().padding(.leading, 16)
        }
    }
}

// MARK: - Dashboard Empty Row

struct DashboardEmptyRow: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }
}

#Preview {
    DashboardView()
        .environmentObject(APIClient())
}
