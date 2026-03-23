import SwiftUI

struct MoviesView: View {
    @EnvironmentObject var apiClient: APIClient
    @State private var showingAddForm = false
    @State private var movieToEdit: Movie?
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
            
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 160, maximum: 200))],
                    spacing: 16
                ) {
                    ForEach(filteredMovies) { movie in
                        MediaCard(
                            imageUrl: movie.imageUrl,
                            title: movie.title,
                            subtitle: movie.director,
                            detailLine: movie.cost.map { "Cost: \($0.currencyDisplayText)" },
                            status: movie.status,
                            onEdit: { movieToEdit = movie }
                        ) {
                            apiClient.deleteMovie(id: movie.id)
                        }
                    }
                }
                .padding(20)
            }
        }
        .sheet(isPresented: $showingAddForm) {
            AddMovieForm(isPresented: $showingAddForm)
                .environmentObject(apiClient)
        }
        .sheet(item: $movieToEdit) { movie in
            EditMovieForm(movie: movie)
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
    @State private var cost = ""
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
                    TextField("Cost", text: $cost)
                    TextField("Rating", text: $rating)
                    TextField("Runtime (minutes)", text: $runtimeMinutes)
                }
                
                Section("Image") {
                    TextField("Image URL or File Path", text: $imageUrl)
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

#Preview {
    MoviesView()
        .environmentObject(APIClient())
}

struct EditMovieForm: View {
    @EnvironmentObject var apiClient: APIClient
    @Environment(\.dismiss) private var dismiss
    let movie: Movie

    @State private var title: String
    @State private var director: String
    @State private var cast: String
    @State private var yearReleased: String
    @State private var studio: String
    @State private var genre: String
    @State private var cost: String
    @State private var rating: String
    @State private var imageUrl: String

    init(movie: Movie) {
        self.movie = movie
        _title = State(initialValue: movie.title)
        _director = State(initialValue: movie.director ?? "")
        _cast = State(initialValue: movie.cast ?? "")
        _yearReleased = State(initialValue: movie.yearReleased.map(String.init) ?? "")
        _studio = State(initialValue: movie.studio ?? "")
        _genre = State(initialValue: movie.genre ?? "")
        _cost = State(initialValue: movie.cost.map { String(format: "%.2f", $0) } ?? "")
        _rating = State(initialValue: movie.rating ?? "")
        _imageUrl = State(initialValue: movie.imageUrl ?? "")
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Movie")
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
                    TextField("Cost", text: $cost)
                    TextField("Rating", text: $rating)
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
                    apiClient.updateMovie(
                        id: movie.id,
                        title: title,
                        director: director.isEmpty ? nil : director,
                        cast: cast.isEmpty ? nil : cast,
                        yearReleased: Int(yearReleased),
                        studio: studio.isEmpty ? nil : studio,
                        genre: genre.isEmpty ? nil : genre,
                        rating: rating.isEmpty ? nil : rating,
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
        .frame(minWidth: 500, minHeight: 550)
    }
}
