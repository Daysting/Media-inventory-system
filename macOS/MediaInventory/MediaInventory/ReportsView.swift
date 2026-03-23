import SwiftUI

// MARK: - Root Reports View

struct ReportsView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var selectedReport: ReportKind = .inventorySummary

    enum ReportKind: String, CaseIterable {
        case inventorySummary  = "Summary"
        case borrowerActivity  = "Borrowers"
        case checkoutHistory   = "History"
        case genreDistribution = "Genres"
        case overdueItems      = "Overdue"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Toolbar: report picker + refresh
            HStack(spacing: 16) {
                Picker("", selection: $selectedReport) {
                    ForEach(ReportKind.allCases, id: \.self) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 520)

                Spacer()

                Button {
                    loadCurrentReport()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(apiClient.isLoadingReport)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(nsColor: NSColor.controlBackgroundColor))
            .overlay(alignment: .bottom) {
                Divider()
            }

            if apiClient.isLoadingReport {
                ProgressView("Loading report…")
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Group {
                    switch selectedReport {
                    case .inventorySummary:  InventorySummaryReportView()
                    case .borrowerActivity:  BorrowerActivityReportView()
                    case .checkoutHistory:   CheckoutHistoryReportView()
                    case .genreDistribution: GenreDistributionReportView()
                    case .overdueItems:      OverdueItemsReportView()
                    }
                }
                .environmentObject(apiClient)
            }
        }
        .onAppear { loadCurrentReport() }
        .onChange(of: selectedReport) { _ in loadCurrentReport() }
    }

    private func loadCurrentReport() {
        switch selectedReport {
        case .inventorySummary:  apiClient.fetchInventorySummary()
        case .borrowerActivity:  apiClient.fetchBorrowerActivity()
        case .checkoutHistory:   apiClient.fetchCheckoutHistoryReport()
        case .genreDistribution: apiClient.fetchGenreDistribution()
        case .overdueItems:      apiClient.fetchOverdueItems()
        }
    }
}

// MARK: - Inventory Summary

struct InventorySummaryReportView: View {
    @EnvironmentObject var apiClient: APIClient

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let s = apiClient.inventorySummary {
                    SectionLabel("Collection")
                    Grid(alignment: .topLeading, horizontalSpacing: 16, verticalSpacing: 16) {
                        GridRow {
                            ReportStatCard(icon: "📚", title: "Books",
                                           value: "\(s.books.total)",
                                           detail: "\(s.books.owned) owned")
                            ReportStatCard(icon: "🎮", title: "Video Games",
                                           value: "\(s.videoGames.total)",
                                           detail: "\(s.videoGames.owned) owned")
                            ReportStatCard(icon: "🎬", title: "Movies",
                                           value: "\(s.movies.total)",
                                           detail: "\(s.movies.owned) owned")
                            ReportStatCard(icon: "💻", title: "Electronics",
                                           value: "\(s.electronics.total)",
                                           detail: "\(s.electronics.owned) owned")
                        }
                    }

                    SectionLabel("Activity")
                    Grid(alignment: .topLeading, horizontalSpacing: 16, verticalSpacing: 16) {
                        GridRow {
                            ReportStatCard(icon: "👥", title: "Borrowers",
                                           value: "\(s.borrowersTotal)",
                                           detail: "registered")
                            ReportStatCard(icon: "📤", title: "Checked Out",
                                           value: "\(s.currentlyCheckedOut)",
                                           detail: "currently out")
                            ReportStatCard(icon: "📋", title: "Total Checkouts",
                                           value: "\(s.totalCheckoutHistory)",
                                           detail: "all time")
                        }
                    }
                } else {
                    Text("No data available. Press Refresh to load.")
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                }
            }
            .padding(20)
        }
    }
}

private struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .tracking(1)
    }
}

struct ReportStatCard: View {
    let icon: String
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(icon).font(.system(size: 26))
            Text(value)
                .font(.system(size: 28, weight: .semibold))
            Text(title)
                .font(.system(size: 13, weight: .medium))
            Text(detail)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(nsColor: NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Borrower Activity

struct BorrowerActivityReportView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var sortOrder = [KeyPathComparator(\BorrowerActivityEntry.totalReturned,
                                                       order: .reverse)]

    var body: some View {
        Table(apiClient.borrowerActivity.sorted(using: sortOrder), sortOrder: $sortOrder) {
            TableColumn("Name", value: \.name)
                .width(min: 140)

            TableColumn("Currently Out", value: \.currentlyCheckedOut) { entry in
                Text("\(entry.currentlyCheckedOut)")
            }
            .width(120)

            TableColumn("Total Returned", value: \.totalReturned) { entry in
                Text("\(entry.totalReturned)")
            }
            .width(130)

            TableColumn("Last Activity", value: \.lastActivity) { entry in
                Text(formattedDate(entry.lastActivity))
                    .foregroundColor(.secondary)
            }
            .width(150)
        }
        .padding(.horizontal, 20)
    }

    private func formattedDate(_ raw: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = fmt.date(from: raw) else { return raw.isEmpty ? "—" : raw }
        let out = DateFormatter()
        out.dateStyle = .medium
        out.timeStyle = .none
        return out.string(from: date)
    }
}

// MARK: - Checkout History

struct CheckoutHistoryReportView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var sortOrder = [KeyPathComparator(\CheckoutHistoryEntry.checkoutDate,
                                                       order: .reverse)]

    var body: some View {
        Table(apiClient.checkoutHistoryEntries.sorted(using: sortOrder), sortOrder: $sortOrder) {
            TableColumn("Media Title", value: \.mediaTitle)
                .width(min: 160)

            TableColumn("Type") { entry in
                Text(mediaTypeLabel(entry.mediaType))
                    .foregroundColor(.secondary)
            }
            .width(70)

            TableColumn("Borrower", value: \.borrowerName)
                .width(min: 120)

            TableColumn("Checked Out", value: \.checkoutDate) { entry in
                Text(formattedDate(entry.checkoutDate))
            }
            .width(130)

            TableColumn("Returned") { entry in
                Text(entry.returnDate.map { formattedDate($0) } ?? "—")
                    .foregroundColor(entry.status == "checked_out" ? .orange : .secondary)
            }
            .width(130)

            TableColumn("Status") { entry in
                StatusBadge(status: entry.status)
            }
            .width(90)
        }
        .padding(.horizontal, 20)
    }

    private func mediaTypeLabel(_ raw: String) -> String {
        switch raw {
        case "books": return "Book"
        case "video_games": return "Game"
        case "movies": return "Movie"
        default: return raw.capitalized
        }
    }

    private func formattedDate(_ raw: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = fmt.date(from: raw) else { return raw }
        let out = DateFormatter()
        out.dateStyle = .medium
        out.timeStyle = .none
        return out.string(from: date)
    }
}

struct StatusBadge: View {
    let status: String
    private var isOut: Bool { status == "checked_out" }

    var body: some View {
        Text(isOut ? "Out" : "Returned")
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(isOut ? Color.orange.opacity(0.18) : Color.green.opacity(0.18))
            .foregroundColor(isOut ? .orange : .green)
            .cornerRadius(6)
    }
}

// MARK: - Genre Distribution

struct GenreDistributionReportView: View {
    @EnvironmentObject var apiClient: APIClient

    enum MediaCategory: String, CaseIterable {
        case books      = "Books"
        case videoGames = "Video Games"
        case movies     = "Movies"
    }

    @State private var selectedCategory: MediaCategory = .books

    private var genres: [GenreCount] {
        guard let dist = apiClient.genreDistribution else { return [] }
        switch selectedCategory {
        case .books:      return dist.books
        case .videoGames: return dist.videoGames
        case .movies:     return dist.movies
        }
    }

    private var maxCount: Int { genres.map(\.count).max() ?? 1 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker("", selection: $selectedCategory) {
                    ForEach(MediaCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 380)

                if genres.isEmpty {
                    Text("No genre data available for \(selectedCategory.rawValue).")
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(genres) { genre in
                            GenreBar(name: genre.name, count: genre.count, maxCount: maxCount)
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

private struct GenreBar: View {
    let name: String
    let count: Int
    let maxCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.system(size: 13))
                    .frame(minWidth: 110, alignment: .leading)
                Spacer()
                Text("\(count)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.12))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.65))
                        .frame(
                            width: max(4, geo.size.width * CGFloat(count) / CGFloat(maxCount)),
                            height: 10
                        )
                }
            }
            .frame(height: 10)
        }
    }
}

// MARK: - Overdue Items

struct OverdueItemsReportView: View {
    @EnvironmentObject var apiClient: APIClient

    var body: some View {
        if apiClient.overdueItems.isEmpty {
            VStack(spacing: 14) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.green)
                Text("No overdue items")
                    .font(.headline)
                Text("All checked-out items are within the 30-day window.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(40)
        } else {
            Table(apiClient.overdueItems) {
                TableColumn("Media Title", value: \.mediaTitle)
                    .width(min: 160)

                TableColumn("Type") { item in
                    Text(mediaTypeLabel(item.mediaType))
                        .foregroundColor(.secondary)
                }
                .width(70)

                TableColumn("Borrower", value: \.borrowerName)
                    .width(min: 120)

                TableColumn("Checked Out") { item in
                    Text(formattedDate(item.checkoutDate))
                }
                .width(130)

                TableColumn("Days Out") { item in
                    Text("\(item.daysOverdue)")
                        .foregroundColor(item.daysOverdue > 60 ? .red : .orange)
                        .fontWeight(.semibold)
                }
                .width(80)
            }
            .padding(.horizontal, 20)
        }
    }

    private func mediaTypeLabel(_ raw: String) -> String {
        switch raw {
        case "books": return "Book"
        case "video_games": return "Game"
        case "movies": return "Movie"
        default: return raw.capitalized
        }
    }

    private func formattedDate(_ raw: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = fmt.date(from: raw) else { return raw }
        let out = DateFormatter()
        out.dateStyle = .medium
        out.timeStyle = .none
        return out.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    ReportsView()
        .environmentObject(APIClient())
        .frame(width: 900, height: 600)
}
