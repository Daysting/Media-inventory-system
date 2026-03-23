import SwiftUI

struct GamesView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var showingAddForm = false
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
            
            Table(filteredGames) {
                TableColumn("Title", value: \.title)
                TableColumn("Developer") { game in
                    Text(game.developer ?? "-")
                }
                TableColumn("Platform") { game in
                    Text(game.platform ?? "-")
                }
                TableColumn("Genre") { game in
                    Text(game.genre ?? "-")
                }
                TableColumn("Status") { game in
                    Badge(game.status)
                }
                TableColumn("") { game in
                    Button(action: { apiClient.deleteGame(id: game.id) }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(20)
            
            Spacer()
        }
        .sheet(isPresented: $showingAddForm) {
            AddGameForm(isPresented: $showingAddForm)
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
                    TextField("Rating", text: $rating)
                }
                
                Section("Image") {
                    TextField("Image URL", text: $imageUrl)
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
        .frame(minWidth: 500, minHeight: 500)
    }
}

#Preview {
    GamesView()
        .environmentObject(APIClient())
}
