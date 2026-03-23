import SwiftUI

struct BooksView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var showingAddForm = false
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
            
            // Books Table
            Table(filteredBooks) {
                TableColumn("Title", value: \.title)
                TableColumn("Author") { book in
                    Text(book.author ?? "-")
                }
                TableColumn("Genre") { book in
                    Text(book.genre ?? "-")
                }
                TableColumn("Year") { book in
                    Text(String(book.yearPublished ?? 0))
                }
                TableColumn("Status") { book in
                    Badge(book.status)
                }
                TableColumn("") { book in
                    HStack(spacing: 8) {
                        Button(action: { apiClient.deleteBook(id: book.id) }) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(20)
            
            Spacer()
        }
        .sheet(isPresented: $showingAddForm) {
            AddBookForm(isPresented: $showingAddForm)
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
                }
                
                Section("Description") {
                    TextEditor(text: $description)
                }
                
                Section("Image") {
                    TextField("Image URL", text: $imageUrl)
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
                        imageUrl: imageUrl.isEmpty ? nil : imageUrl
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

#Preview {
    BooksView()
        .environmentObject(APIClient())
}
