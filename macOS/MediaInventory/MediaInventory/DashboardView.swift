import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var apiClient: APIClient
    var navigate: (ContentView.Tab) -> Void = { _ in }

    var body: some View {
        ScrollView {
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
                        ClickableStatCard(icon: "�", title: "Electronics",
                                          value: String(apiClient.electronics.count)) { navigate(.electronics) }
                    }
                    GridRow {
                        ClickableStatCard(icon: "👥", title: "Borrowers",
                                          value: String(apiClient.borrowers.count)) { navigate(.borrowers) }
                        Color.clear
                        Color.clear
                        Color.clear
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // MARK: Most Popular
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Most Popular")
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                        Text("Based on checkout history")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)

                    if apiClient.isLoadingReport {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        Grid(alignment: .topLeading, horizontalSpacing: 16, verticalSpacing: 16) {
                            GridRow {
                                PopularItemCard(icon: "📚", category: "Top Book",
                                                item: apiClient.mostPopular?.book) { navigate(.books) }
                                PopularItemCard(icon: "🎮", category: "Top Game",
                                                item: apiClient.mostPopular?.game) { navigate(.games) }
                                PopularItemCard(icon: "🎬", category: "Top Movie",
                                                item: apiClient.mostPopular?.movie) { navigate(.movies) }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                Spacer(minLength: 20)
            }
        }
        .onAppear {
            apiClient.fetchMostPopular()
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

// MARK: - Popular Item Card

struct PopularItemCard: View {
    let icon: String
    let category: String
    let item: PopularItem?
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    AsyncImage(url: {
                        guard let s = item?.imageUrl else { return nil }
                        return URL(string: s)
                    }()) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            Color.gray.opacity(0.10)
                            Text(icon).font(.system(size: 44))
                        }
                    }
                }
                .frame(height: 160)
                .clipped()

                VStack(alignment: .leading, spacing: 5) {
                    Text(category)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    if let item {
                        Text(item.title)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(2)
                        if !item.subtitle.isEmpty {
                            Text(item.subtitle)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        Label("\(item.checkoutCount) checkout\(item.checkoutCount == 1 ? "" : "s")",
                              systemImage: "arrow.up.right.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.blue)
                    } else {
                        Text("No items in collection")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
            }
            .background(
                isHovering
                    ? Color.blue.opacity(0.05)
                    : Color(nsColor: NSColor.controlBackgroundColor)
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(isHovering ? 0.10 : 0.05),
                    radius: isHovering ? 6 : 4)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHovering ? Color.blue.opacity(0.30) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovering = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovering)
    }
}

#Preview {
    DashboardView()
        .environmentObject(APIClient())
}
