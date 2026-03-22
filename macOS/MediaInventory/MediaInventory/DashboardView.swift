import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var apiClient: APIClient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Statistics Grid
            Grid(alignment: .topLeading, horizontalSpacing: 16, verticalSpacing: 16) {
                GridRow {
                    StatCard(
                        icon: "📚",
                        title: "Books",
                        value: String(apiClient.books.count)
                    )
                    StatCard(
                        icon: "🎮",
                        title: "Video Games",
                        value: String(apiClient.games.count)
                    )
                    StatCard(
                        icon: "🎬",
                        title: "Movies",
                        value: String(apiClient.movies.count)
                    )
                    StatCard(
                        icon: "👥",
                        title: "Borrowers",
                        value: String(apiClient.borrowers.count)
                    )
                }
            }
            .padding(20)
            
            Spacer()
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
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
        .background(Color(nsColor: NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
    }
}

#Preview {
    DashboardView()
        .environmentObject(APIClient())
}
