import SwiftUI
import AppKit

// MARK: - Root Reports View

struct ReportsView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var selectedReport: ReportKind = .inventorySummary
    @State private var showPreview: Bool = false

    enum ReportKind: String, CaseIterable {
        case inventorySummary   = "Summary"
        case borrowerActivity   = "Borrowers"
        case checkoutHistory    = "History"
        case genreDistribution  = "Genres"
        case overdueItems       = "Overdue"
        case booksCatalog       = "Books"
        case gamesCatalog       = "Games"
        case moviesCatalog      = "Movies"
        case electronicsCatalog = "Electronics"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Toolbar: report picker + buttons
            HStack(spacing: 12) {
                Text("Report:")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                Picker("", selection: $selectedReport) {
                    ForEach(ReportKind.allCases, id: \.self) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .frame(width: 180)

                Spacer()

                Button {
                    showPreview.toggle()
                } label: {
                    Label(showPreview ? "Hide Preview" : "Show Preview", systemImage: "eye")
                }
                .buttonStyle(.borderless)
                .disabled(apiClient.isLoadingReport)

                Button {
                    printCurrentReport()
                } label: {
                    Label("Print", systemImage: "printer")
                }
                .buttonStyle(.borderless)
                .disabled(apiClient.isLoadingReport)

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
            } else if showPreview {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        printPreviewContent()
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(20)
                }
            } else {
                Group {
                    switch selectedReport {
                    case .inventorySummary:  InventorySummaryReportView()
                    case .borrowerActivity:  BorrowerActivityReportView()
                    case .checkoutHistory:   CheckoutHistoryReportView()
                    case .genreDistribution: GenreDistributionReportView()
                    case .overdueItems:      OverdueItemsReportView()
                    case .booksCatalog:      BooksCatalogReportView()
                    case .gamesCatalog:      GamesCatalogReportView()
                    case .moviesCatalog:     MoviesCatalogReportView()
                    case .electronicsCatalog: ElectronicsCatalogReportView()
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
        case .booksCatalog, .gamesCatalog, .moviesCatalog, .electronicsCatalog:
            break // data already loaded at startup
        }
    }

    @ViewBuilder
    private func printPreviewContent() -> some View {
        switch selectedReport {
        case .inventorySummary:
            if let s = apiClient.inventorySummary {
                PrintableInventorySummary(summary: s)
            } else {
                Text("No data available.").foregroundColor(.secondary)
            }
        case .borrowerActivity:
            PrintableBorrowerActivityReport(entries: apiClient.borrowerActivity)
        case .checkoutHistory:
            PrintableCheckoutHistoryReport(entries: apiClient.checkoutHistoryEntries)
        case .genreDistribution:
            if let dist = apiClient.genreDistribution {
                PrintableGenreReport(distribution: dist)
            } else {
                Text("No data available.").foregroundColor(.secondary)
            }
        case .overdueItems:
            PrintableOverdueReport(items: apiClient.overdueItems)
        case .booksCatalog:
            PrintableBooksCatalog(books: apiClient.books)
        case .gamesCatalog:
            PrintableGamesCatalog(games: apiClient.games)
        case .moviesCatalog:
            PrintableMoviesCatalog(movies: apiClient.movies)
        case .electronicsCatalog:
            PrintableElectronicsCatalog(electronics: apiClient.electronics)
        }
    }

    // MARK: - Print

    private func printCurrentReport() {
        let now = Date()
        switch selectedReport {
        case .inventorySummary:
            guard let s = apiClient.inventorySummary else { return }
            sendToPrinter(AnyView(PrintableInventorySummary(summary: s)),
                          title: "Inventory Summary", date: now)
        case .borrowerActivity:
            sendToPrinter(AnyView(PrintableBorrowerActivityReport(entries: apiClient.borrowerActivity)),
                          title: "Borrower Activity", date: now)
        case .checkoutHistory:
            sendToPrinter(AnyView(PrintableCheckoutHistoryReport(entries: apiClient.checkoutHistoryEntries)),
                          title: "Checkout History", date: now)
        case .genreDistribution:
            guard let dist = apiClient.genreDistribution else { return }
            sendToPrinter(AnyView(PrintableGenreReport(distribution: dist)),
                          title: "Genre Distribution", date: now)
        case .overdueItems:
            sendToPrinter(AnyView(PrintableOverdueReport(items: apiClient.overdueItems)),
                          title: "Overdue Items", date: now)
        case .booksCatalog:
            sendToPrinter(AnyView(PrintableBooksCatalog(books: apiClient.books)),
                          title: "Books Catalog", date: now)
        case .gamesCatalog:
            sendToPrinter(AnyView(PrintableGamesCatalog(games: apiClient.games)),
                          title: "Games Catalog", date: now)
        case .moviesCatalog:
            sendToPrinter(AnyView(PrintableMoviesCatalog(movies: apiClient.movies)),
                          title: "Movies Catalog", date: now)
        case .electronicsCatalog:
            sendToPrinter(AnyView(PrintableElectronicsCatalog(electronics: apiClient.electronics)),
                          title: "Electronics Catalog", date: now)
        }
    }

    private func sendToPrinter(_ content: AnyView, title: String, date: Date) {
        let pi = NSPrintInfo.shared.copy() as! NSPrintInfo
        pi.topMargin    = 36; pi.bottomMargin = 36
        pi.leftMargin   = 36; pi.rightMargin  = 36
        pi.horizontalPagination = .fit
        pi.verticalPagination   = .automatic
        pi.isHorizontallyCentered = false
        pi.isVerticallyCentered   = false

        let pageWidth = pi.paperSize.width - pi.leftMargin - pi.rightMargin

        let page = PrintReportPage(title: title, generatedAt: date, content: content)
        let host = NSHostingView(rootView: page)
        host.frame = NSRect(x: 0, y: 0, width: pageWidth, height: 100)

        // The window must be ordered into the window server session (even if invisible)
        // so that the compositor allocates a real CGContext. Without this, NSPrintOperation's
        // drawRect gets a null context and CoreGraphics logs CGContextClipToRect errors.
        let printWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: pageWidth, height: 100),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        // Disable all scene/restoration tracking for this ephemeral window.
        printWindow.isReleasedWhenClosed = true
        printWindow.isOpaque = false
        printWindow.alphaValue = 0
        printWindow.isRestorable = false
        printWindow.restorationClass = nil
        printWindow.identifier = NSUserInterfaceItemIdentifier("")

        printWindow.contentView = host
        printWindow.orderFrontRegardless()

        host.layoutSubtreeIfNeeded()
        let fittedHeight = max(host.fittingSize.height, 200)
        host.frame = NSRect(x: 0, y: 0, width: pageWidth, height: fittedHeight)
        printWindow.setContentSize(NSSize(width: pageWidth, height: fittedHeight))

        let op = NSPrintOperation(view: host, printInfo: pi)
        op.jobTitle = "Daysting’s Home Inventory – \(title)"
        op.showsPrintPanel    = true
        op.showsProgressPanel = true
        op.run()

        // Clean up: remove from scene tracking, then close and release.
        printWindow.orderOut(nil)
        DispatchQueue.main.async {
            // Delay close to ensure print operation is fully finished.
            printWindow.close()
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
            TableColumn("Borrower ID", value: \.id)
                .width(90)

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
            TableColumn("Item ID", value: \.mediaId)
                .width(90)

            TableColumn("Borrower ID", value: \.borrowerId)
                .width(90)

            TableColumn("Media Title", value: \.mediaTitle)
                .width(min: 140)

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
                TableColumn("Item ID") { item in
                    Text(item.mediaId)
                        .foregroundColor(.secondary)
                }
                .width(90)

                TableColumn("Borrower ID") { item in
                    Text(item.borrowerId)
                        .foregroundColor(.secondary)
                }
                .width(90)

                TableColumn("Media Title", value: \.mediaTitle)
                    .width(min: 140)

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

// MARK: - Books Catalog

struct BooksCatalogReportView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var sortOrder = [KeyPathComparator(\Book.title)]

    var body: some View {
        Table(apiClient.books.sorted(using: sortOrder), sortOrder: $sortOrder) {
            TableColumn("ID", value: \.id).width(90)
            TableColumn("Title", value: \.title).width(min: 140)
            TableColumn("Author") { b in Text(b.author ?? "—") }.width(min: 110)
            TableColumn("Year") { b in Text(b.yearPublished.map(String.init) ?? "—") }.width(60)
            TableColumn("Genre") { b in Text(b.genre ?? "—") }.width(90)
            TableColumn("Cost") { b in Text(b.cost?.currencyDisplayText ?? "—") }.width(80)
            TableColumn("Status") { b in StatusBadge(status: b.status) }.width(80)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Games Catalog

struct GamesCatalogReportView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var sortOrder = [KeyPathComparator(\Game.title)]

    var body: some View {
        Table(apiClient.games.sorted(using: sortOrder), sortOrder: $sortOrder) {
            TableColumn("ID", value: \.id).width(90)
            TableColumn("Title", value: \.title).width(min: 140)
            TableColumn("Platform") { g in Text(g.platform ?? "—") }.width(90)
            TableColumn("Year") { g in Text(g.yearReleased.map(String.init) ?? "—") }.width(60)
            TableColumn("Genre") { g in Text(g.genre ?? "—") }.width(90)
            TableColumn("Cost") { g in Text(g.cost?.currencyDisplayText ?? "—") }.width(80)
            TableColumn("Status") { g in StatusBadge(status: g.status) }.width(80)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Movies Catalog

struct MoviesCatalogReportView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var sortOrder = [KeyPathComparator(\Movie.title)]

    var body: some View {
        Table(apiClient.movies.sorted(using: sortOrder), sortOrder: $sortOrder) {
            TableColumn("ID", value: \.id).width(90)
            TableColumn("Title", value: \.title).width(min: 140)
            TableColumn("Director") { m in Text(m.director ?? "—") }.width(110)
            TableColumn("Year") { m in Text(m.yearReleased.map(String.init) ?? "—") }.width(60)
            TableColumn("Genre") { m in Text(m.genre ?? "—") }.width(90)
            TableColumn("Cost") { m in Text(m.cost?.currencyDisplayText ?? "—") }.width(80)
            TableColumn("Status") { m in StatusBadge(status: m.status) }.width(80)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Electronics Catalog

struct ElectronicsCatalogReportView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var sortOrder = [KeyPathComparator(\Electronic.title)]

    var body: some View {
        Table(apiClient.electronics.sorted(using: sortOrder), sortOrder: $sortOrder) {
            TableColumn("ID", value: \.id).width(90)
            TableColumn("Title", value: \.title).width(min: 140)
            TableColumn("Serial Number") { e in Text(e.serialNumber ?? "—") }.width(130)
            TableColumn("Cost") { e in Text(e.cost?.currencyDisplayText ?? "—") }.width(80)
            TableColumn("Status") { e in StatusBadge(status: e.status) }.width(80)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview

#Preview {
    ReportsView()
        .environmentObject(APIClient())
        .frame(width: 900, height: 600)
}
