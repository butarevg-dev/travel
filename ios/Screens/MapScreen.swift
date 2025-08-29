import SwiftUI
import CoreLocation

struct MapScreen: View {
    @StateObject private var provider = MapKitProvider()
    @StateObject private var locationService = LocationService.shared
    @State private var pois: [POI] = []
    @State private var routes: [Route] = []
    @State private var categoryFilter: String? = nil
    @State private var nearbyMode = false
    @State private var nearbyRadius: Double = 1000 // meters
    @State private var showFilters = false
    @State private var selectedRoute: Route? = nil
    @State private var routeTimeInfo: RouteTimeInfo? = nil

    var body: some View {
        ZStack(alignment: .top) {
            provider.representable()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top controls
                HStack {
                    // Category filter button
                    Button {
                        showFilters.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(categoryFilter ?? "Все")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    // Route selection button
                    Menu {
                        Button("Скрыть маршруты") {
                            selectedRoute = nil
                            routeTimeInfo = nil
                            refreshMap()
                        }
                        ForEach(routes, id: \.id) { route in
                            Button(route.title) {
                                selectedRoute = route
                                calculateRouteTime(route)
                                showRouteOnMap(route)
                            }
                        }
                    } label: {
                        Image(systemName: "map.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(selectedRoute != nil ? .red : .primary)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                    }
                    
                    // Nearby mode button
                    Button {
                        toggleNearbyMode()
                    } label: {
                        Image(systemName: nearbyMode ? "location.fill" : "location")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(nearbyMode ? .red : .primary)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                    }
                    
                    // Center map button
                    Button {
                        centerOnSaransk()
                    } label: {
                        Image(systemName: "map")
                            .font(.system(size: 16, weight: .medium))
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Category filters panel
                if showFilters {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(title: "Все", isSelected: categoryFilter == nil) {
                                categoryFilter = nil
                                refreshPins()
                                showFilters = false
                            }
                            
                            CategoryChip(title: "Архитектура", isSelected: categoryFilter == "архитектура") {
                                categoryFilter = "архитектура"
                                refreshPins()
                                showFilters = false
                            }
                            
                            CategoryChip(title: "Музеи", isSelected: categoryFilter == "музеи") {
                                categoryFilter = "музеи"
                                refreshPins()
                                showFilters = false
                            }
                            
                            CategoryChip(title: "Еда", isSelected: categoryFilter == "еда") {
                                categoryFilter = "еда"
                                refreshPins()
                                showFilters = false
                            }
                            
                            CategoryChip(title: "Сувениры", isSelected: categoryFilter == "сувениры") {
                                categoryFilter = "сувениры"
                                refreshPins()
                                showFilters = false
                            }
                            
                            CategoryChip(title: "Развлечения", isSelected: categoryFilter == "развлечения") {
                                categoryFilter = "развлечения"
                                refreshPins()
                                showFilters = false
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Nearby radius slider
                if nearbyMode {
                    VStack(spacing: 4) {
                        HStack {
                            Text("Радиус поиска")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(nearbyRadius))м")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                        }
                        
                        Slider(value: $nearbyRadius, in: 500...5000, step: 500) { _ in
                            refreshPins()
                        }
                        .accentColor(.red)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                // Route info panel
                if let timeInfo = routeTimeInfo, let route = selectedRoute {
                    RouteInfoPanel(route: route, timeInfo: timeInfo)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Audio player
                MiniAudioPlayer()
            }
        }
        .onAppear {
            Task { 
                await loadPOI()
                await loadRoutes()
            }
            centerOnSaransk()
        }
        .onChange(of: locationService.authorizationStatus) { _ in
            if locationService.authorizationStatus == .authorizedWhenInUse {
                provider.setUserLocationEnabled(true)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showFilters)
        .animation(.easeInOut(duration: 0.3), value: nearbyMode)
        .animation(.easeInOut(duration: 0.3), value: routeTimeInfo != nil)
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
    
    private func loadRoutes() async {
        do {
            let list = try await FirestoreService.shared.fetchRouteList()
            await MainActor.run {
                self.routes = list
            }
        } catch {
            // handle error or keep empty
        }
    }
    
    private func calculateRouteTime(_ route: Route) {
        let timeInfo = RouteCalculator.shared.calculateTotalRouteTime(route: route, pois: pois)
        routeTimeInfo = timeInfo
    }

    private func refreshPins() {
        var filtered = pois
        
        // Apply category filter
        if let cat = categoryFilter {
            filtered = filtered.filter { $0.categories.contains(cat) }
        }
        
        // Apply nearby filter
        if nearbyMode, let userLocation = locationService.userLocation {
            filtered = filtered.filter { poi in
                let poiLocation = CLLocation(latitude: poi.coordinates.lat, longitude: poi.coordinates.lng)
                return userLocation.distance(from: poiLocation) <= nearbyRadius
            }
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
    
    private func refreshMap() {
        refreshPins()
        if let route = selectedRoute {
            showRouteOnMap(route)
        }
    }
    
    private func showRouteOnMap(_ route: Route) {
        // Create polyline from route coordinates
        let coordinates = route.polyline.map { coord in
            CLLocationCoordinate2D(latitude: coord.lat, longitude: coord.lng)
        }
        
        let polyline = MapRoutePolyline(
            id: route.id,
            title: route.title,
            coordinates: coordinates,
            color: .red
        )
        
        provider.setPolylines([polyline])
        
        // Fit map to show the entire route
        if !coordinates.isEmpty {
            let region = MKCoordinateRegion(coordinates: coordinates)
            provider.setRegion(center: region.center, spanDegrees: max(region.span.latitudeDelta, region.span.longitudeDelta) * 1.2)
        }
    }

    private func toggleNearbyMode() {
        nearbyMode.toggle()
        if nearbyMode {
            if locationService.authorizationStatus == .notDetermined {
                locationService.requestPermission()
            } else if locationService.authorizationStatus == .authorizedWhenInUse {
                provider.setUserLocationEnabled(true)
                refreshPins()
            }
        } else {
            refreshPins()
        }
    }

    private func centerOnSaransk() {
        provider.setRegion(center: CLLocationCoordinate2D(latitude: 54.1834, longitude: 45.1749), spanDegrees: 0.12)
    }
}

struct RouteInfoPanel: View {
    let route: Route
    let timeInfo: RouteTimeInfo
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(route.title)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text(timeInfo.formattedTotalTime)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
            }
            
            HStack(spacing: 16) {
                InfoItem(icon: "figure.walk", title: "Ходьба", value: timeInfo.formattedWalkingTime)
                InfoItem(icon: "mappin.circle", title: "Точки", value: "\(timeInfo.poiCount)")
                InfoItem(icon: "location", title: "Расстояние", value: timeInfo.formattedDistance)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct InfoItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 12, weight: .semibold))
            }
        }
    }
}

// Extension to help with coordinate region calculations
extension MKCoordinateRegion {
    init(coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else {
            self.init()
            return
        }
        
        let minLat = coordinates.map { $0.latitude }.min()!
        let maxLat = coordinates.map { $0.latitude }.max()!
        let minLng = coordinates.map { $0.longitude }.min()!
        let maxLng = coordinates.map { $0.longitude }.max()!
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.1,
            longitudeDelta: (maxLng - minLng) * 1.1
        )
        
        self.init(center: center, span: span)
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.red : Color.clear)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}