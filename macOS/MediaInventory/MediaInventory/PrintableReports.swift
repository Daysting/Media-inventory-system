import SwiftUI

// MARK: - Print Page Wrapper

/// Wraps any report content with a standard header for printing.
struct PrintReportPage: View {
    let title: String
    let generatedAt: Date
    let content: AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Daysting's Home Inventory System")
                    .font(.system(size: 17, weight: .bold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Text("Generated: \(Self.dateFmt.string(from: generatedAt))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            Divider()
            content
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(36)
        .background(Color.white)
    }

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        return f
    }()
}

// MARK: - Generic Print Table

struct PrintTable: View {
    struct Col {
        let title: String
        let width: CGFloat
        var align: Alignment = .leading
    }

    let columns: [Col]
    let rows: [[String]]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                ForEach(Array(columns.enumerated()), id: \.offset) { _, col in
                    Text(col.title)
                        .font(.system(size: 8.5, weight: .semibold))
                        .frame(width: col.width, alignment: col.align)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 5)
                        .background(Color(white: 0.90))
                }
            }
            Divider().background(Color.gray)

            // Data rows
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIdx, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { colIdx, cell in
                        Text(cell)
                            .font(.system(size: 8.5))
                            .lineLimit(2)
                            .frame(width: columns[safeIdx: colIdx]?.width ?? 80,
                                   alignment: columns[safeIdx: colIdx]?.align ?? .leading)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 4)
                    }
                }
                .background(rowIdx % 2 == 0 ? Color.white : Color(white: 0.97))
                Divider().opacity(0.35)
            }
        }
        .overlay(Rectangle().stroke(Color(white: 0.78), lineWidth: 0.5))
    }
}

private extension Array {
    subscript(safeIdx index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Printable: Inventory Summary

struct PrintableInventorySummary: View {
    let summary: InventorySummaryReport

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionBlock("Collection") {
                PrintTable(
                    columns: [
                        .init(title: "Category", width: 140),
                        .init(title: "Total",    width: 80, align: .center),
                        .init(title: "Owned",    width: 80, align: .center),
                    ],
                    rows: [
                        ["Books",       "\(summary.books.total)",       "\(summary.books.owned)"],
                        ["Video Games", "\(summary.videoGames.total)",  "\(summary.videoGames.owned)"],
                        ["Movies",      "\(summary.movies.total)",      "\(summary.movies.owned)"],
                        ["Electronics", "\(summary.electronics.total)", "\(summary.electronics.owned)"],
                    ]
                )
            }
            sectionBlock("Activity") {
                PrintTable(
                    columns: [
                        .init(title: "Metric", width: 220),
                        .init(title: "Value",  width: 80, align: .center),
                    ],
                    rows: [
                        ["Registered Borrowers",   "\(summary.borrowersTotal)"],
                        ["Currently Checked Out",  "\(summary.currentlyCheckedOut)"],
                        ["Total Checkout History", "\(summary.totalCheckoutHistory)"],
                    ]
                )
            }
        }
    }

    @ViewBuilder
    private func sectionBlock<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)
            content()
        }
    }
}

// MARK: - Printable: Books Catalog

struct PrintableBooksCatalog: View {
    let books: [Book]

    private static let cols: [PrintTable.Col] = [
        .init(title: "Item ID", width: 72),
        .init(title: "Title",   width: 150),
        .init(title: "Author",  width: 110),
        .init(title: "Year",    width: 44, align: .center),
        .init(title: "Genre",   width: 80),
        .init(title: "Cost",    width: 60, align: .trailing),
        .init(title: "Status",  width: 56),
    ]

    var body: some View {
        PrintTable(columns: Self.cols, rows: books.map { b in [
            b.id,
            b.title,
            b.author ?? "—",
            b.yearPublished.map(String.init) ?? "—",
            b.genre ?? "—",
            b.cost?.currencyDisplayText ?? "—",
            b.status.replacingOccurrences(of: "_", with: " ").capitalized,
        ]})
    }
}

// MARK: - Printable: Games Catalog

struct PrintableGamesCatalog: View {
    let games: [Game]

    private static let cols: [PrintTable.Col] = [
        .init(title: "Item ID",  width: 72),
        .init(title: "Title",    width: 150),
        .init(title: "Platform", width: 90),
        .init(title: "Year",     width: 44, align: .center),
        .init(title: "Genre",    width: 80),
        .init(title: "Cost",     width: 60, align: .trailing),
        .init(title: "Status",   width: 56),
    ]

    var body: some View {
        PrintTable(columns: Self.cols, rows: games.map { g in [
            g.id,
            g.title,
            g.platform ?? "—",
            g.yearReleased.map(String.init) ?? "—",
            g.genre ?? "—",
            g.cost?.currencyDisplayText ?? "—",
            g.status.replacingOccurrences(of: "_", with: " ").capitalized,
        ]})
    }
}

// MARK: - Printable: Movies Catalog

struct PrintableMoviesCatalog: View {
    let movies: [Movie]

    private static let cols: [PrintTable.Col] = [
        .init(title: "Item ID",  width: 72),
        .init(title: "Title",    width: 150),
        .init(title: "Director", width: 110),
        .init(title: "Year",     width: 44, align: .center),
        .init(title: "Genre",    width: 70),
        .init(title: "Rating",   width: 54),
        .init(title: "Cost",     width: 58, align: .trailing),
        .init(title: "Status",   width: 56),
    ]

    var body: some View {
        PrintTable(columns: Self.cols, rows: movies.map { m in [
            m.id,
            m.title,
            m.director ?? "—",
            m.yearReleased.map(String.init) ?? "—",
            m.genre ?? "—",
            m.rating ?? "—",
            m.cost?.currencyDisplayText ?? "—",
            m.status.replacingOccurrences(of: "_", with: " ").capitalized,
        ]})
    }
}

// MARK: - Printable: Electronics Catalog

struct PrintableElectronicsCatalog: View {
    let electronics: [Electronic]

    private static let cols: [PrintTable.Col] = [
        .init(title: "Item ID",       width: 80),
        .init(title: "Title",         width: 160),
        .init(title: "Serial Number", width: 140),
        .init(title: "Cost",          width: 68, align: .trailing),
        .init(title: "Status",        width: 68),
    ]

    var body: some View {
        PrintTable(columns: Self.cols, rows: electronics.map { e in [
            e.id,
            e.title,
            e.serialNumber ?? "—",
            e.cost?.currencyDisplayText ?? "—",
            e.status.replacingOccurrences(of: "_", with: " ").capitalized,
        ]})
    }
}

// MARK: - Printable: Borrowers List

struct PrintableBorrowersReport: View {
    let borrowers: [Borrower]

    private static let cols: [PrintTable.Col] = [
        .init(title: "Borrower ID", width: 80),
        .init(title: "Name",        width: 140),
        .init(title: "Phone",       width: 110),
        .init(title: "Email",       width: 160),
        .init(title: "Address",     width: 150),
    ]

    var body: some View {
        PrintTable(columns: Self.cols, rows: borrowers.map { b in [
            b.id,
            b.fullName,
            b.phoneNumber ?? "—",
            b.email ?? "—",
            b.address ?? "—",
        ]})
    }
}

// MARK: - Printable: Borrower Activity

struct PrintableBorrowerActivityReport: View {
    let entries: [BorrowerActivityEntry]

    private static let cols: [PrintTable.Col] = [
        .init(title: "Borrower ID",    width: 80),
        .init(title: "Name",           width: 140),
        .init(title: "Currently Out",  width: 90, align: .center),
        .init(title: "Total Returned", width: 100, align: .center),
        .init(title: "Last Activity",  width: 110),
    ]

    var body: some View {
        PrintTable(columns: Self.cols, rows: entries.map { e in [
            e.id,
            e.name,
            "\(e.currentlyCheckedOut)",
            "\(e.totalReturned)",
            fmtDate(e.lastActivity),
        ]})
    }

    private func fmtDate(_ raw: String) -> String {
        let p = DateFormatter(); p.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let d = p.date(from: raw) else { return raw.isEmpty ? "—" : raw }
        let o = DateFormatter(); o.dateStyle = .medium; o.timeStyle = .none
        return o.string(from: d)
    }
}

// MARK: - Printable: Checkout History

struct PrintableCheckoutHistoryReport: View {
    let entries: [CheckoutHistoryEntry]

    private static let cols: [PrintTable.Col] = [
        .init(title: "Item ID",     width: 72),
        .init(title: "Borrower ID", width: 72),
        .init(title: "Title",       width: 120),
        .init(title: "Type",        width: 50),
        .init(title: "Borrower",    width: 110),
        .init(title: "Checked Out", width: 84),
        .init(title: "Returned",    width: 84),
        .init(title: "Status",      width: 60),
    ]

    var body: some View {
        PrintTable(columns: Self.cols, rows: entries.map { e in [
            e.mediaId,
            e.borrowerId,
            e.mediaTitle,
            mediaLabel(e.mediaType),
            e.borrowerName,
            fmtDate(e.checkoutDate),
            e.returnDate.map { fmtDate($0) } ?? "—",
            e.status == "checked_out" ? "Out" : "Returned",
        ]})
    }

    private func mediaLabel(_ raw: String) -> String {
        switch raw {
        case "books": return "Book"
        case "video_games": return "Game"
        case "movies": return "Movie"
        default: return raw.capitalized
        }
    }

    private func fmtDate(_ raw: String) -> String {
        let p = DateFormatter(); p.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let d = p.date(from: raw) else { return raw }
        let o = DateFormatter(); o.dateStyle = .medium; o.timeStyle = .none
        return o.string(from: d)
    }
}

// MARK: - Printable: Overdue Items

struct PrintableOverdueReport: View {
    let items: [OverdueItem]

    private static let cols: [PrintTable.Col] = [
        .init(title: "Item ID",     width: 72),
        .init(title: "Borrower ID", width: 72),
        .init(title: "Title",       width: 136),
        .init(title: "Type",        width: 50),
        .init(title: "Borrower",    width: 110),
        .init(title: "Checked Out", width: 88),
        .init(title: "Days Out",    width: 58, align: .center),
    ]

    var body: some View {
        PrintTable(columns: Self.cols, rows: items.map { item in [
            item.mediaId,
            item.borrowerId,
            item.mediaTitle,
            mediaLabel(item.mediaType),
            item.borrowerName,
            fmtDate(item.checkoutDate),
            "\(item.daysOverdue)",
        ]})
    }

    private func mediaLabel(_ raw: String) -> String {
        switch raw {
        case "books": return "Book"
        case "video_games": return "Game"
        case "movies": return "Movie"
        default: return raw.capitalized
        }
    }

    private func fmtDate(_ raw: String) -> String {
        let p = DateFormatter(); p.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let d = p.date(from: raw) else { return raw }
        let o = DateFormatter(); o.dateStyle = .medium; o.timeStyle = .none
        return o.string(from: d)
    }
}

// MARK: - Printable: Genre Distribution

struct PrintableGenreReport: View {
    let distribution: GenreDistributionReport

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            genreSection("Books",       genres: distribution.books)
            genreSection("Video Games", genres: distribution.videoGames)
            genreSection("Movies",      genres: distribution.movies)
        }
    }

    @ViewBuilder
    private func genreSection(_ title: String, genres: [GenreCount]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.8)
            PrintTable(
                columns: [
                    .init(title: "Genre", width: 120),
                    .init(title: "Count", width: 50, align: .center),
                ],
                rows: genres.map { ["\($0.name)", "\($0.count)"] }
            )
        }
    }
}
