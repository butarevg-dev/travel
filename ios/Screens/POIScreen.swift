import SwiftUI

struct POIScreen: View {
    @StateObject private var viewModel = POIViewModel()
    @StateObject private var userService = UserService.shared
    @StateObject private var gamificationService = GamificationService.shared
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var showFavoritesOnly = false
    
    var filteredPOIs: [POI] {
        var pois = viewModel.pois
        
        // Apply search filter
        if !searchText.isEmpty {
            pois = pois.filter { poi in
                poi.title.localizedCaseInsensitiveContains(searchText) ||
                poi.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            pois = pois.filter { $0.categories.contains(category) }
        }
        
        // Apply favorites filter
        if showFavoritesOnly {
            pois = pois.filter { viewModel.favorites.contains($0.id) }
        }
        
        return pois
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and filters
                VStack(spacing: 8) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Поиск по названию...", text: $searchText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    
                    // Category filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(title: "Все", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            
                            ForEach(Array(Set(viewModel.pois.flatMap { $0.categories })).sorted(), id: \.self) { category in
                                CategoryChip(title: category.capitalized, isSelected: selectedCategory == category) {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Favorites toggle
                    HStack {
                        Toggle("Только избранное", isOn: $showFavoritesOnly)
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                        Text("\(filteredPOIs.count) мест")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                
                // POI list
                List(filteredPOIs, id: \.id) { poi in
                    NavigationLink(destination: POIDetailView(poi: poi, viewModel: viewModel)) {
                        POIListItem(poi: poi, isFavorite: viewModel.favorites.contains(poi.id)) {
                            viewModel.toggleFavorite(poi.id)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Каталог POI")
            .onAppear {
                Task {
                    await viewModel.loadPOIs()
                }
            }
        }
    }
}

struct POIListItem: View {
    let poi: POI
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // POI image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "mappin.circle")
                        .font(.title2)
                        .foregroundColor(.red)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(poi.title)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                    Spacer()
                    Button(action: onFavoriteToggle) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .gray)
                    }
                }
                
                Text(poi.short)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    ForEach(poi.categories.prefix(2), id: \.self) { category in
                        Text(category)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", poi.rating))
                            .font(.system(size: 12, weight: .medium))
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct POIDetailView: View {
    let poi: POI
    @ObservedObject var viewModel: POIViewModel
    @StateObject private var audioService = AudioPlayerService.shared
    @StateObject private var gamificationService = GamificationService.shared
    @State private var rating: Int = 0
    @State private var comment: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header image
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "mappin.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.red)
                            Text("Фото \(poi.title)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
                
                VStack(alignment: .leading, spacing: 12) {
                    // Title and favorite
                    HStack {
                        Text(poi.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: { 
                            viewModel.toggleFavorite(poi.id)
                            Task {
                                await gamificationService.likePOI(poi.id)
                            }
                        }) {
                            Image(systemName: viewModel.favorites.contains(poi.id) ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundColor(viewModel.favorites.contains(poi.id) ? .red : .gray)
                        }
                    }
                    
                    // Rating
                    HStack {
                        Text("Рейтинг:")
                            .font(.system(size: 14, weight: .medium))
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= poi.rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .onTapGesture { rating = i }
                        }
                        Text(String(format: "%.1f", poi.rating))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    // Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(poi.categories, id: \.self) { category in
                                Text(category)
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Description
                    Text("Описание")
                        .font(.system(size: 16, weight: .semibold))
                    Text(poi.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    // Working hours and ticket info
                    if let hours = poi.openingHours {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Время работы")
                                .font(.system(size: 14, weight: .semibold))
                            Text(hours)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let ticket = poi.ticket {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Стоимость")
                                .font(.system(size: 14, weight: .semibold))
                            Text(ticket)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Audio guide button
                    if !poi.audio.isEmpty {
                        Button(action: playAudioGuide) {
                            HStack {
                                Image(systemName: "headphones")
                                Text("poi_audio_guide", bundle: .main)
                                Spacer()
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                        }
                        .accessibilityLabel(Text("poi_audio_guide", bundle: .main))
                        .accessibilityHint(Text("poi_audio_guide_hint", bundle: .main))
                    }
                    
                    // Comments section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Комментарии")
                            .font(.system(size: 16, weight: .semibold))
                        
                        TextField("Оставить комментарий...", text: $comment, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                        
                        Button("Отправить") {
                            Task {
                                // TODO: Submit comment to ReviewService
                                // For now, just trigger gamification event
                                await gamificationService.likePOI(poi.id)
                                comment = ""
                            }
                        }
                        .disabled(comment.isEmpty)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Детали")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func playAudioGuide() {
        guard let audioURL = poi.audio.first else { return }
        
        // Create a mock URL for demonstration
        // In a real app, this would be a real audio file URL
        let url = URL(string: audioURL) ?? URL(string: "https://example.com/audio.m4a")!
        
        audioService.loadAudio(from: url, title: "Аудиогид: \(poi.title)", poiId: poi.id)
    }
}

class POIViewModel: ObservableObject {
    @Published var pois: [POI] = []
    @Published var favorites: Set<String> = []
    
    func loadPOIs() async {
        do {
            let list = try await FirestoreService.shared.fetchPOIList()
            await MainActor.run {
                self.pois = list
            }
        } catch {
            // Handle error
        }
    }
    
    func toggleFavorite(_ poiId: String) {
        if favorites.contains(poiId) {
            favorites.remove(poiId)
        } else {
            favorites.insert(poiId)
        }
        // TODO: Save to UserDefaults or backend
    }
}