import SwiftUI
import CoreLocation

struct MapScreen: View {
    @StateObject private var provider = MapKitProvider()
    @State private var pois: [POI] = []
    @State private var categoryFilter: String? = nil

    var body: some View {
        ZStack(alignment: .top) {
            provider.representable()
                .ignoresSafeArea()
            VStack(spacing: 8) {
                HStack {
                    Menu(categoryFilter ?? "Все категории") {
                        Button("Все категории") { categoryFilter = nil; refreshPins() }
                        Button("Архитектура") { categoryFilter = "архитектура"; refreshPins() }
                        Button("Музеи") { categoryFilter = "музеи"; refreshPins() }
                        Button("Еда") { categoryFilter = "еда"; refreshPins() }
                        Button("Сувениры") { categoryFilter = "сувениры"; refreshPins() }
                        Button("Развлечения") { categoryFilter = "развлечения"; refreshPins() }
                    }
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    Spacer()
                    Button {
                        centerOnSaransk()
                    } label: {
                        Image(systemName: "location.circle")
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                Spacer()
                MiniAudioPlayerMock().padding()
            }
        }
        .onAppear {
            Task { await loadPOI() }
            centerOnSaransk()
        }
    }

    private func loadPOI() async {
        do {
            let list = try await FirestoreService.shared.fetchPOIList()
            await MainActor.run {
                self.pois = list
                refreshPins()
            }
        } catch {
            // handle error or keep empty
        }
    }

    private func refreshPins() {
        let filtered = pois.filter { poi in
            guard let cat = categoryFilter else { return true }
            return poi.categories.contains(cat)
        }
        let items = filtered.map { poi in
            MapPOIAnnotation(
                id: poi.id,
                title: poi.title,
                coordinate: CLLocationCoordinate2D(latitude: poi.coordinates.lat, longitude: poi.coordinates.lng),
                category: poi.categories.first ?? ""
            )
        }
        provider.setAnnotations(items)
    }

    private func centerOnSaransk() {
        provider.setRegion(center: CLLocationCoordinate2D(latitude: 54.1834, longitude: 45.1749), spanDegrees: 0.12)
    }
}

struct MiniAudioPlayerMock: View {
    @State private var isPlaying = false
    @State private var progress: Double = 0.35
    @State private var speed: Double = 1.0

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Button(action: { /* back 10s */ }) { Image(systemName: "gobackward.10") }
                Button(action: { isPlaying.toggle() }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                }
                Button(action: { /* forward 10s */ }) { Image(systemName: "goforward.10") }
                Spacer()
                Menu("x\(String(format: "%.1f", speed))") {
                    Button("0.5x") { speed = 0.5 }
                    Button("1.0x") { speed = 1.0 }
                    Button("1.5x") { speed = 1.5 }
                    Button("2.0x") { speed = 2.0 }
                }
                Button(action: { /* download */ }) { Image(systemName: "arrow.down.circle") }
            }
            .font(.title3)
            Slider(value: $progress)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}