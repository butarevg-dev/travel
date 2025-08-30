import SwiftUI

struct RoutesScreen: View {
    @StateObject private var viewModel = RoutesViewModel()
    @StateObject private var routeBuilder = RouteBuilderService.shared
    @StateObject private var gamificationService = GamificationService.shared
    @State private var searchText = ""
    @State private var selectedPresetType: RouteBuilderService.PresetRouteType? = nil
    @State private var showingCustomRouteBuilder = false
    @State private var customRouteParameters = CustomRouteParameters()
    
    var filteredRoutes: [Route] {
        if searchText.isEmpty {
            return viewModel.routes
        } else {
            return viewModel.routes.filter { route in
                route.title.localizedCaseInsensitiveContains(searchText) ||
                (route.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Поиск маршрутов...", text: $searchText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Preset routes section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Быстрые маршруты")
                        .font(.headline)
                        .padding(.horizontal, 16)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(RouteBuilderService.PresetRouteType.allCases, id: \.self) { presetType in
                                PresetRouteCard(
                                    presetType: presetType,
                                    isSelected: selectedPresetType == presetType,
                                    onTap: {
                                        selectedPresetType = presetType
                                        generatePresetRoute(presetType)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
                // Custom route builder
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Создать маршрут")
                            .font(.headline)
                        Spacer()
                        Button("Настроить") {
                            showingCustomRouteBuilder = true
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    .padding(.horizontal, 16)
                    
                    CustomRouteBuilderView(
                        parameters: $customRouteParameters,
                        onGenerate: generateCustomRoute
                    )
                    .padding(.horizontal, 16)
                }
                
                // Routes list
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Все маршруты")
                            .font(.headline)
                        Spacer()
                        Text("\(filteredRoutes.count) маршрутов")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    
                    List(filteredRoutes, id: \.id) { route in
                        NavigationLink(destination: RouteDetailScreen(route: route)) {
                            RouteListItem(route: route)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Маршруты")
            .sheet(isPresented: $showingCustomRouteBuilder) {
                CustomRouteBuilderSheet(parameters: $customRouteParameters)
            }
            .onAppear {
                Task {
                    await viewModel.loadRoutes()
                }
            }
        }
    }
    
    private func generatePresetRoute(_ presetType: RouteBuilderService.PresetRouteType) {
        Task {
            await viewModel.generatePresetRoute(presetType)
        }
    }
    
    private func generateCustomRoute() {
        Task {
            await viewModel.generateCustomRoute(parameters: customRouteParameters.toRouteParameters())
        }
    }
}

struct PresetRouteCard: View {
    let presetType: RouteBuilderService.PresetRouteType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: presetType.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .red)
                
                Text(presetType.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? Color.red : Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomRouteParameters {
    var selectedInterests: Set<String> = []
    var maxDuration: Double = 180 // minutes
    var includeAudioGuides = true
    var includeRestaurants = false
    var includeShopping = false
    
    func toRouteParameters() -> RouteBuilderService.RouteParameters {
        return RouteBuilderService.RouteParameters(
            interests: Array(selectedInterests),
            maxDuration: maxDuration * 60, // convert to seconds
            startLocation: nil,
            preferredCategories: Array(selectedInterests),
            avoidCategories: [],
            maxDistance: 10.0,
            includeAudioGuides: includeAudioGuides,
            includeRestaurants: includeRestaurants,
            includeShopping: includeShopping
        )
    }
}

struct CustomRouteBuilderView: View {
    @Binding var parameters: CustomRouteParameters
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Interests selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Интересы")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(availableInterests, id: \.self) { interest in
                        InterestToggle(
                            title: interest,
                            isSelected: parameters.selectedInterests.contains(interest),
                            onToggle: { isSelected in
                                if isSelected {
                                    parameters.selectedInterests.insert(interest)
                                } else {
                                    parameters.selectedInterests.remove(interest)
                                }
                            }
                        )
                    }
                }
            }
            
            // Duration slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Время маршрута")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(parameters.maxDuration)) мин")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $parameters.maxDuration, in: 60...480, step: 30)
                    .accentColor(.red)
            }
            
            // Options
            VStack(spacing: 8) {
                Toggle("Включить аудиогиды", isOn: $parameters.includeAudioGuides)
                Toggle("Включить рестораны", isOn: $parameters.includeRestaurants)
                Toggle("Включить шоппинг", isOn: $parameters.includeShopping)
            }
            .font(.caption)
            
            // Generate button
            Button(action: onGenerate) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("Создать маршрут")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(parameters.selectedInterests.isEmpty)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private var availableInterests: [String] {
        return ["архитектура", "история", "музеи", "развлечения", "семейный", "еда", "сувениры"]
    }
}

struct InterestToggle: View {
    let title: String
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: { onToggle(!isSelected) }) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.red : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomRouteBuilderSheet: View {
    @Binding var parameters: CustomRouteParameters
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                CustomRouteBuilderView(parameters: $parameters) {
                    dismiss()
                }
                .padding()
            }
            .navigationTitle("Создать маршрут")
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

struct RouteListItem: View {
    let route: Route
    
    var body: some View {
        HStack(spacing: 12) {
            // Route image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "map")
                        .font(.title2)
                        .foregroundColor(.red)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(route.title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                
                if let description = route.description {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("\(route.durationMinutes) мин")
                            .font(.system(size: 12, weight: .medium))
                    }
                    
                    // Distance
                    if let distance = route.distanceKm {
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f км", distance))
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    
                    // Stops count
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("\(route.stops.count) точек")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

class RoutesViewModel: ObservableObject {
    @Published var routes: [Route] = []
    @Published var generatedRoutes: [RouteBuilderService.GeneratedRoute] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func loadRoutes() async {
        do {
            let routesList = try await FirestoreService.shared.fetchRouteList()
            let poisList = try await FirestoreService.shared.fetchPOIList()
            
            await MainActor.run {
                self.routes = routesList
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
    
    func generatePresetRoute(_ presetType: RouteBuilderService.PresetRouteType) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let pois = try await FirestoreService.shared.fetchPOIList()
            let generatedRoute = await RouteBuilderService.shared.generateCustomRoute(
                parameters: presetType.parameters,
                pois: pois
            )
            
            if let route = generatedRoute {
                await MainActor.run {
                    // Convert GeneratedRoute to Route and add to list
                    let newRoute = convertGeneratedRouteToRoute(route)
                    self.routes.insert(newRoute, at: 0)
                }
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func generateCustomRoute(parameters: RouteBuilderService.RouteParameters) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let pois = try await FirestoreService.shared.fetchPOIList()
            let generatedRoute = await RouteBuilderService.shared.generateCustomRoute(
                parameters: parameters,
                pois: pois
            )
            
            if let route = generatedRoute {
                await MainActor.run {
                    // Convert GeneratedRoute to Route and add to list
                    let newRoute = convertGeneratedRouteToRoute(route)
                    self.routes.insert(newRoute, at: 0)
                }
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    private func convertGeneratedRouteToRoute(_ generatedRoute: RouteBuilderService.GeneratedRoute) -> Route {
        return Route(
            id: generatedRoute.id,
            title: generatedRoute.title,
            durationMinutes: Int(generatedRoute.totalDuration / 60),
            distanceKm: generatedRoute.totalDistance,
            interests: generatedRoute.interests,
            stops: generatedRoute.stops,
            polyline: generatedRoute.polyline,
            tags: generatedRoute.tags,
            meta: nil,
            description: generatedRoute.description
        )
    }
}