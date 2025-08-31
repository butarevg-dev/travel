import SwiftUI
import MapKit

struct MapScreen: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var selectedPOI: POI?
    @State private var showingPOIDetail = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        NavigationView {
            AdaptiveLayout {
                ZStack {
                    // Основная карта
                    CustomMapView(
                        pois: viewModel.pois,
                        selectedPOI: $selectedPOI,
                        userLocation: viewModel.userLocation
                    )
                    
                    // Поисковая панель
                    VStack {
                        SearchPanel(
                            searchText: $viewModel.searchText,
                            selectedCategory: $viewModel.selectedCategory
                        )
                        .padding(.top, horizontalSizeClass == .compact ? AppSpacing.md : AppSpacing.lg)
                        
                        Spacer()
                        
                        // Панель фильтров
                        if !viewModel.searchText.isEmpty || viewModel.selectedCategory != nil {
                            FilterPanel(
                                selectedCategory: $viewModel.selectedCategory,
                                selectedFilters: $viewModel.selectedFilters
                            )
                            .padding(.bottom, horizontalSizeClass == .compact ? AppSpacing.md : AppSpacing.lg)
                        }
                    }
                }
            }
            .navigationTitle("Карта")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Фильтры") {
                        viewModel.showingFilters = true
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Мое местоположение") {
                        viewModel.centerOnUserLocation()
                    }
                }
            }
            .sheet(isPresented: $showingPOIDetail) {
                if let poi = selectedPOI {
                    POIDetailView(poi: poi)
                }
            }
            .sheet(isPresented: $viewModel.showingFilters) {
                FilterView(selectedFilters: $viewModel.selectedFilters)
            }
        }
    }
}

// MARK: - CustomMapView
struct CustomMapView: UIViewRepresentable {
    let pois: [POI]
    @Binding var selectedPOI: POI?
    let userLocation: CLLocation?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Обновление маркеров POI
        mapView.removeAnnotations(mapView.annotations)
        
        let annotations = pois.map { poi in
            POIAnnotation(poi: poi)
        }
        mapView.addAnnotations(annotations)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        
        init(_ parent: CustomMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let poiAnnotation = annotation as? POIAnnotation else { return nil }
            
            let identifier = "POIAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            }
            
            annotationView?.image = UIImage(systemName: "mappin.circle.fill")
            annotationView?.annotation = annotation
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let poiAnnotation = view.annotation as? POIAnnotation {
                parent.selectedPOI = poiAnnotation.poi
            }
        }
    }
}

// MARK: - SearchPanel
struct SearchPanel: View {
    @Binding var searchText: String
    @Binding var selectedCategory: String?
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Поисковая строка
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textSecondary)
                
                TextField("Поиск достопримечательностей...", text: $searchText)
                    .font(AppTypography.body)
                
                if !searchText.isEmpty {
                    Button("Очистить") {
                        searchText = ""
                    }
                    .font(AppTypography.caption1)
                    .foregroundColor(AppColors.primary)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(AppCornerRadius.large)
            
            // Быстрые категории
            if searchText.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(["Музеи", "Храмы", "Парки", "Рестораны"], id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
        }
    }
}

// MARK: - FilterPanel
struct FilterPanel: View {
    @Binding var selectedCategory: String?
    @Binding var selectedFilters: [String]
    
    var body: some View {
        HStack {
            Text("Фильтры:")
                .font(AppTypography.caption1)
                .foregroundColor(AppColors.textSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(selectedFilters, id: \.self) { filter in
                        CategoryChip(
                            category: filter,
                            isSelected: true
                        ) {
                            selectedFilters.removeAll { $0 == filter }
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
    }
}

// MARK: - POIAnnotation
class POIAnnotation: NSObject, MKAnnotation {
    let poi: POI
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    
    init(poi: POI) {
        self.poi = poi
        self.coordinate = CLLocationCoordinate2D(latitude: poi.latitude, longitude: poi.longitude)
        self.title = poi.name
        self.subtitle = poi.address
        super.init()
    }
}

// MARK: - MapViewModel
class MapViewModel: ObservableObject {
    @Published var pois: [POI] = []
    @Published var searchText = ""
    @Published var selectedCategory: String?
    @Published var selectedFilters: [String] = []
    @Published var showingFilters = false
    @Published var userLocation: CLLocation?
    
    func centerOnUserLocation() {
        // Логика центрирования на местоположении пользователя
    }
}

// MARK: - FilterView
struct FilterView: View {
    @Binding var selectedFilters: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Категории") {
                    ForEach(["Музеи", "Храмы", "Парки", "Рестораны", "Кафе"], id: \.self) { category in
                        HStack {
                            Text(category)
                            Spacer()
                            if selectedFilters.contains(category) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedFilters.contains(category) {
                                selectedFilters.removeAll { $0 == category }
                            } else {
                                selectedFilters.append(category)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - POIDetailView
struct POIDetailView: View {
    let poi: POI
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Изображение
                    AsyncImage(url: URL(string: poi.imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(AppColors.surface)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(AppColors.textSecondary)
                            )
                    }
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(AppCornerRadius.medium)
                    
                    // Информация
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text(poi.name)
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.text)
                        
                        Text(poi.description)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.text)
                        
                        Text(poi.address)
                            .font(AppTypography.caption1)
                            .foregroundColor(AppColors.textSecondary)
                        
                        HStack {
                            AppButton(title: "Навигация", style: .primary) {
                                // Открыть навигацию
                            }
                            
                            AppButton(title: "Поделиться", style: .outline) {
                                // Поделиться POI
                            }
                        }
                    }
                    .padding(AppSpacing.md)
                }
            }
            .navigationTitle("Детали")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MapScreen()
}