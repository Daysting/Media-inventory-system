import SwiftUI

struct MoviesView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var showingAddForm = false
    @State private var searchText = ""
    
    var filteredMovies: [Movie] {
        if searchText.isEmpty {
            return apiClient.movies
        }
        return apiClient.movies.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.director?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button(action: { showingAddForm = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Movie")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(6)
                }
                
                SearchField(text: $searchText, placeholder: "Search movies...")
            }
            .padding(20)
            .background(Color(nsColor: NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(20)
            
            Table(filteredMovies) {
                TableColumn("Title", value: \.title)
                TableColumn("Director") { movie in
                    Text(movie.director ?? "-")
                }
                TableColumn("Genre") { movie in
                    Text(movie.genre ?? "-")
                }
                TableColumn("Rating") { movie in
                    Text(movie.rating ?? "-")
                }
                TableColumn("Status") { movie in
                    Badge(movie.status)
                }
                TableColumn("") { movie in
                    Button(action: { apiClient.deleteMovie(id: movie.id) }) {
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
            AddMovieForm(isPresented: $showingAddForm)
                .environmentObject(apiClient)
        }
        .onAppear {
            apiClient.fetchMovies()
        }
    }
}

struct AddMovieForm: View {
    @EnvironmentObject var apiClient: APIClient
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var director = ""
    @State private var cast = ""
    @State private var yearReleased = ""
    @State private var studio = ""
    @State private var genre = ""
    @State private var rating = ""
    @State private var runtimeMinutes = ""
    @State private var imageUrl = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Add New Movie")
                .font(.system(size: 18, weight: .semibold))
            
            Form {
                Section("Basic Information") {
                    TextField("Title *", text: $title)
                    TextField("Director", text: $director)
                    TextField("Cast", text: $cast)
                    TextField("Year Released", text: $yearReleased)
                }
                
                Section("Details") {
                    TextField("Studio", text: $studio)
                    TextField("Genre", text: $genre)
                    TextField("Rating", text: $rating)
                    TextField("Runtime (minutes)", text: $runtimeMinutes)
                }
                
                Section("Image") {
                    TextField("Image URL", text: $imageUrl)
                }
            }
            
            HStack {
                Button("Cancel") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Add Movie") {
                    apiClient.addMovie(
                        title: title,
                        director: director.isEmpty ? nil : director,
                        yearReleased: Int(yearReleased),
                        genre: genre.isEmpty ? nil : genre,
                        rating: rating.isEmpty ? nil : rating,
                        runtimeMinutes: Int(runtimeMinutes),
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

#Preview {
    MoviesView()
        .environmentObject(APIClient())
}
