import SwiftUI

struct GamesView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var showingAddForm = false
    @State private var gameToEdit: Game?
    @State private var searchText = ""
    
    var filteredGames: [Game] {
        if searchText.isEmpty {
            return apiClient.games
        }
        return apiClient.games.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button(action: { showingAddForm = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Game")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(6)
                }
                
                SearchField(text: $searchText, placeholder: "Search games...")
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
                    ForEach(filteredGames) { game in
                        MediaCard(
                            imageUrl: game.imageUrl,
                            title: game.title,
                            subtitle: game.platform,
                            detailLine: game.cost.map { "Cost: \($0.currencyDisplayText)" },
                            status: game.status,
                            onEdit: { gameToEdit = game }
                        ) {
                            apiClient.deleteGame(id: game.id)
                        }
                    }
                }
                .padding(20)
            }
        }
        .sheet(isPresented: $showingAddForm) {
            AddGameForm(isPresented: $showingAddForm)
                .environmentObject(apiClient)
        }
        .sheet(item: $gameToEdit) { game in
            EditGameForm(game: game)
                .environmentObject(apiClient)
        }
        .onAppear {
            apiClient.fetchGames()
        }
    }
}

struct AddGameForm: View {
    @EnvironmentObject var apiClient: APIClient
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var developer = ""
    @State private var platform = ""
    @State private var yearReleased = ""
    @State private var genre = ""
    @State private var cost = ""
    @State private var rating = ""
    @State private var imageUrl = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Add New Video Game")
                .font(.system(size: 18, weight: .semibold))
            
            Form {
                Section("Basic Information") {
                    TextField("Title *", text: $title)
                    TextField("Developer", text: $developer)
                    TextField("Platform", text: $platform)
                    TextField("Year Released", text: $yearReleased)
                }
                
                Section("Details") {
                    TextField("Genre", text: $genre)
                    TextField("Cost", text: $cost)
                    TextField("Rating", text: $rating)
                }
                
                Section("Image") {
                    TextField("Image URL or File Path", text: $imageUrl)
                }
            }
            
            HStack {
                Button("Cancel") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Add Game") {
                    apiClient.addGame(
                        title: title,
                        developer: developer.isEmpty ? nil : developer,
                        platform: platform.isEmpty ? nil : platform,
                        yearReleased: Int(yearReleased),
                        genre: genre.isEmpty ? nil : genre,
                        rating: rating.isEmpty ? nil : rating,
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
        .frame(minWidth: 500, minHeight: 500)
    }
}

#Preview {
    GamesView()
        .environmentObject(APIClient())
}

struct EditGameForm: View {
    @EnvironmentObject var apiClient: APIClient
    @Environment(\.dismiss) private var dismiss
    let game: Game

    @State private var title: String
    @State private var platform: String
    @State private var yearReleased: String
    @State private var genre: String
    @State private var cost: String
    @State private var imageUrl: String

    init(game: Game) {
        self.game = game
        _title = State(initialValue: game.title)
        _platform = State(initialValue: game.platform ?? "")
        _yearReleased = State(initialValue: game.yearReleased.map(String.init) ?? "")
        _genre = State(initialValue: game.genre ?? "")
        _cost = State(initialValue: game.cost.map { String(format: "%.2f", $0) } ?? "")
        _imageUrl = State(initialValue: game.imageUrl ?? "")
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Video Game")
                .font(.system(size: 18, weight: .semibold))

            Form {
                Section("Basic Information") {
                    TextField("Title *", text: $title)
                    TextField("Platform", text: $platform)
                    TextField("Year Released", text: $yearReleased)
                }

                Section("Details") {
                    TextField("Genre", text: $genre)
                    TextField("Cost", text: $cost)
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
                    apiClient.updateGame(
                        id: game.id,
                        title: title,
                        platform: platform.isEmpty ? nil : platform,
                        genre: genre.isEmpty ? nil : genre,
                        yearReleased: Int(yearReleased),
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
        .frame(minWidth: 500, minHeight: 450)
    }
}
