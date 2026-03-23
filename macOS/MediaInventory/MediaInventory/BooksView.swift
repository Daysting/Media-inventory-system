import SwiftUI

struct BooksView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var showingAddForm = false
    @State private var bookToEdit: Book?
    @State private var searchText = ""
    
    var filteredBooks: [Book] {
        if searchText.isEmpty {
            return apiClient.books
        }
        return apiClient.books.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.author?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Add Book Button and Search
            HStack {
                Button(action: { showingAddForm = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Book")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(6)
                }
                
                SearchField(text: $searchText, placeholder: "Search books...")
            }
            .padding(20)
            .background(Color(nsColor: NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(20)
            
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 160, maximum: 200))],
                    spacing: 16
                ) {
                    ForEach(filteredBooks) { book in
                        MediaCard(
                            imageUrl: book.imageUrl,
                            title: book.title,
                            subtitle: book.author,
                            detailLine: book.cost.map { "Cost: \($0.currencyDisplayText)" },
                            status: book.status,
                            onEdit: { bookToEdit = book }
                        ) {
                            apiClient.deleteBook(id: book.id)
                        }
                    }
                }
                .padding(20)
            }
        }
        .sheet(isPresented: $showingAddForm) {
            AddBookForm(isPresented: $showingAddForm)
                .environmentObject(apiClient)
        }
        .sheet(item: $bookToEdit) { book in
            EditBookForm(book: book)
                .environmentObject(apiClient)
        }
        .onAppear {
            apiClient.fetchBooks()
        }
    }
}

struct AddBookForm: View {
    @EnvironmentObject var apiClient: APIClient
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var author = ""
    @State private var yearPublished = ""
    @State private var publisher = ""
    @State private var fictionNonfiction = ""
    @State private var genre = ""
    @State private var cost = ""
    @State private var description = ""
    @State private var imageUrl = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Add New Book")
                .font(.system(size: 18, weight: .semibold))
            
            Form {
                Section("Basic Information") {
                    TextField("Title *", text: $title)
                    TextField("Author", text: $author)
                    TextField("Publisher", text: $publisher)
                    TextField("Year Published", text: $yearPublished)
                }
                
                Section("Details") {
                    Picker("Type", selection: $fictionNonfiction) {
                        Text("Select...").tag("")
                        Text("Fiction").tag("Fiction")
                        Text("Non-Fiction").tag("Non-Fiction")
                    }
                    TextField("Genre", text: $genre)
                    TextField("Cost", text: $cost)
                }
                
                Section("Description") {
                    TextEditor(text: $description)
                }
                
                Section("Image") {
                    TextField("Image URL or File Path", text: $imageUrl)
                }
            }
            
            HStack {
                Button("Cancel") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Add Book") {
                    apiClient.addBook(
                        title: title,
                        author: author.isEmpty ? nil : author,
                        yearPublished: Int(yearPublished),
                        publisher: publisher.isEmpty ? nil : publisher,
                        fictionNonfiction: fictionNonfiction.isEmpty ? nil : fictionNonfiction,
                        genre: genre.isEmpty ? nil : genre,
                        description: description.isEmpty ? nil : description,
                        imageUrl: imageUrl.isEmpty ? nil : imageUrl,
                        cost: parseCurrency(cost)
                    )
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
            }
            .padding()
        }
        .padding(20)
        .frame(minWidth: 500, minHeight: 600)
    }
}

struct SearchField: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct Badge: View {
    let status: String
    
    var statusColor: Color {
        switch status.lowercased() {
        case "available": return .green
        case "borrowed": return .orange
        case "reserved": return .blue
        default: return .gray
        }
    }
    
    init(_ status: String) {
        self.status = status
    }
    
    var body: some View {
        Text(status)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }
}

// MARK: - Media Card

struct MediaCard: View {
    let imageUrl: String?
    let title: String
    let subtitle: String?
    let detailLine: String?
    let status: String?
    var onEdit: (() -> Void)?
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: imageUrl.flatMap { URL(string: $0) }) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.12)
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 180)
                .clipped()

                if isHovering {
                    HStack(spacing: 4) {
                        if let onEdit {
                            Button(action: onEdit) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.blue.opacity(0.85))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        Button(action: onDelete) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.red.opacity(0.85))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(2)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                if let detailLine, !detailLine.isEmpty {
                    Text(detailLine)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                if let status {
                    Badge(status).padding(.top, 2)
                }
            }
            .padding(10)
        }
        .background(Color(nsColor: NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .shadow(
            color: Color.black.opacity(isHovering ? 0.12 : 0.05),
            radius: isHovering ? 8 : 3,
            x: 0, y: 2
        )
        .onHover { isHovering = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovering)
    }
}

#Preview {
    BooksView()
        .environmentObject(APIClient())
}

struct EditBookForm: View {
    @EnvironmentObject var apiClient: APIClient
    @Environment(\.dismiss) private var dismiss
    let book: Book

    @State private var title: String
    @State private var author: String
    @State private var yearPublished: String
    @State private var publisher: String
    @State private var fictionNonfiction: String
    @State private var genre: String
    @State private var cost: String
    @State private var description: String
    @State private var imageUrl: String

    init(book: Book) {
        self.book = book
        _title = State(initialValue: book.title)
        _author = State(initialValue: book.author ?? "")
        _yearPublished = State(initialValue: book.yearPublished.map(String.init) ?? "")
        _publisher = State(initialValue: book.publisher ?? "")
        _fictionNonfiction = State(initialValue: book.fictionNonfiction ?? "")
        _genre = State(initialValue: book.genre ?? "")
        _cost = State(initialValue: book.cost.map { String(format: "%.2f", $0) } ?? "")
        _description = State(initialValue: book.description ?? "")
        _imageUrl = State(initialValue: book.imageUrl ?? "")
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Book")
                .font(.system(size: 18, weight: .semibold))

            Form {
                Section("Basic Information") {
                    TextField("Title *", text: $title)
                    TextField("Author", text: $author)
                    TextField("Publisher", text: $publisher)
                    TextField("Year Published", text: $yearPublished)
                }

                Section("Details") {
                    Picker("Type", selection: $fictionNonfiction) {
                        Text("Select...").tag("")
                        Text("Fiction").tag("Fiction")
                        Text("Non-Fiction").tag("Non-Fiction")
                    }
                    TextField("Genre", text: $genre)
                    TextField("Cost", text: $cost)
                }

                Section("Description") {
                    TextEditor(text: $description)
                }

                Section("Image") {
                    TextField("Image URL or File Path", text: $imageUrl)
                }
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save Changes") {
                    apiClient.updateBook(
                        id: book.id,
                        title: title,
                        author: author.isEmpty ? nil : author,
                        yearPublished: Int(yearPublished),
                        publisher: publisher.isEmpty ? nil : publisher,
                        fictionNonfiction: fictionNonfiction.isEmpty ? nil : fictionNonfiction,
                        genre: genre.isEmpty ? nil : genre,
                        description: description.isEmpty ? nil : description,
                        imageUrl: imageUrl.isEmpty ? nil : imageUrl,
                        cost: parseCurrency(cost)
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
            }
            .padding()
        }
        .padding(20)
        .frame(minWidth: 500, minHeight: 600)
    }
}

func parseCurrency(_ rawValue: String) -> Double? {
    let normalized = rawValue
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "$", with: "")
        .replacingOccurrences(of: ",", with: "")

    guard !normalized.isEmpty else { return nil }
    return Double(normalized)
}
