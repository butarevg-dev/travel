import SwiftUI

struct RoutesScreen: View {
    @StateObject private var viewModel = RoutesViewModel()
    @State private var selectedPreset: String? = nil
    @State private var interests: Set<String> = ["архитектура", "история"]
    @State private var minutes: Double = 180
    @State private var showingRouteDetail = false
    @State private var selectedRoute: Route? = nil
    
    var body: some View {
        NavigationStack {
            List {
                Section("Предустановленные маршруты") {
                    ForEach(viewModel.routes, id: \.id) { route in
                        RouteListItem(route: route, timeInfo: viewModel.getTimeInfo(for: route)) {
                            selectedRoute = route
                            showingRouteDetail = true
                        }
                    }
                }
                
                Section("Генерация по интересам") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Выберите интересы:")
                            .font(.system(size: 14, weight: .medium))
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            InterestToggle(title: "Архитектура", isSelected: interests.contains("архитектура")) {
                                toggleInterest("архитектура")
                            }
                            InterestToggle(title: "История", isSelected: interests.contains("история")) {
                                toggleInterest("история")
                            }
                            InterestToggle(title: "Музеи", isSelected: interests.contains("музеи")) {
                                toggleInterest("музеи")
                            }
                            InterestToggle(title: "Еда", isSelected: interests.contains("еда")) {
                                toggleInterest("еда")
                            }
                            InterestToggle(title: "Сувениры", isSelected: interests.contains("сувениры")) {
                                toggleInterest("сувениры")
                            }
                            InterestToggle(title: "Развлечения", isSelected: interests.contains("развлечения")) {
                                toggleInterest("развлечения")
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Время маршрута: \(Int(minutes)) минут")
                                .font(.system(size: 14, weight: .medium))
                            
                            Slider(value: $minutes, in: 60...720, step: 30)
                                .accentColor(.red)
                        }
                        
                        Button("Сгенерировать маршрут") {
                            generateCustomRoute()
                        }
                        .disabled(interests.isEmpty)
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
            }
            .navigationTitle("Маршруты")
            .onAppear {
                Task {
                    await viewModel.loadRoutes()
                }
            }
            .sheet(isPresented: $showingRouteDetail) {
                if let route = selectedRoute {
                    RouteDetailView(route: route, timeInfo: viewModel.getTimeInfo(for: route))
                }
            }
        }
    }
    
    private func toggleInterest(_ interest: String) {
        if interests.contains(interest) {
            interests.remove(interest)
        } else {
            interests.insert(interest)
        }
    }
    
    private func generateCustomRoute() {
        // TODO: Implement custom route generation based on interests and time
        print("Generating route for \(interests) with \(Int(minutes)) minutes")
    }
}

struct RouteListItem: View {
    let route: Route
    let timeInfo: RouteTimeInfo?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(route.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    if let timeInfo = timeInfo {
                        Text(timeInfo.formattedTotalTime)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
                
                Text(route.description ?? "Описание маршрута")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 16) {
                    if let timeInfo = timeInfo {
                        InfoChip(icon: "figure.walk", text: timeInfo.formattedWalkingTime)
                        InfoChip(icon: "mappin.circle", text: "\(timeInfo.poiCount) точек")
                        InfoChip(icon: "location", text: timeInfo.formattedDistance)
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(route.interests, id: \.self) { interest in
                            Text(interest)
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct InfoChip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

struct InterestToggle: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(isSelected ? Color.red : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct RouteDetailView: View {
    let route: Route
    let timeInfo: RouteTimeInfo?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Route header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(route.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let description = route.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        if let timeInfo = timeInfo {
                            HStack(spacing: 16) {
                                InfoChip(icon: "clock", text: timeInfo.formattedTotalTime)
                                InfoChip(icon: "figure.walk", text: timeInfo.formattedWalkingTime)
                                InfoChip(icon: "mappin.circle", text: "\(timeInfo.poiCount) точек")
                                InfoChip(icon: "location", text: timeInfo.formattedDistance)
                            }
                        }
                    }
                    
                    // Route steps
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Точки маршрута")
                            .font(.system(size: 18, weight: .semibold))
                        
                        ForEach(Array(route.stops.enumerated()), id: \.offset) { index, stop in
                            HStack(spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Точка \(index + 1)")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("ID: \(stop.poiId)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Interests
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Интересы")
                            .font(.system(size: 18, weight: .semibold))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(route.interests, id: \.self) { interest in
                                    Text(interest)
                                        .font(.system(size: 12, weight: .medium))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Детали маршрута")
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

class RoutesViewModel: ObservableObject {
    @Published var routes: [Route] = []
    @Published var pois: [POI] = []
    private let routeCalculator = RouteCalculator.shared
    
    func loadRoutes() async {
        do {
            let routesList = try await FirestoreService.shared.fetchRouteList()
            let poisList = try await FirestoreService.shared.fetchPOIList()
            
            await MainActor.run {
                self.routes = routesList
                self.pois = poisList
            }
        } catch {
            print("Error loading routes: \(error)")
        }
    }
    
    func getTimeInfo(for route: Route) -> RouteTimeInfo? {
        return routeCalculator.calculateTotalRouteTime(route: route, pois: pois)
    }
}