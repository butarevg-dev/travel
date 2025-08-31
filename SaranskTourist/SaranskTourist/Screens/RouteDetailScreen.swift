import SwiftUI
import CoreLocation

struct RouteDetailScreen: View {
    let route: Route
    @StateObject private var routeBuilder = RouteBuilderService.shared
    @StateObject private var locationService = LocationService.shared
    @StateObject private var gamificationService = GamificationService.shared
    @State private var currentStepIndex = 0
    @State private var showingShareSheet = false
    @State private var showingCustomization = false
    @State private var routeProgress: Double = 0.0
    @State private var pois: [POI] = []
    @State private var routeTimeInfo: RouteTimeInfo?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with route info
                RouteHeaderView(route: route, timeInfo: routeTimeInfo)
                
                // Progress indicator
                RouteProgressView(
                    currentStep: currentStepIndex,
                    totalSteps: route.stops.count,
                    progress: routeProgress
                )
                
                // Route steps
                RouteStepsView(
                    route: route,
                    pois: pois,
                    currentStepIndex: $currentStepIndex,
                    onStepTap: { index in
                        currentStepIndex = index
                        updateProgress()
                    }
                )
                
                // Action buttons
                RouteActionButtonsView(
                    route: route,
                    onShare: { showingShareSheet = true },
                    onCustomize: { showingCustomization = true },
                    onStart: startRoute
                )
            }
        }
        .navigationTitle("Маршрут")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Поделиться") {
                    showingShareSheet = true
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            RouteShareSheet(route: route)
        }
        .sheet(isPresented: $showingCustomization) {
            RouteCustomizationSheet(route: route)
        }
        .onAppear {
            Task {
                await loadPOIs()
                calculateRouteTime()
                updateProgress()
            }
        }
        .onChange(of: currentStepIndex) { _ in
            updateProgress()
        }
    }
    
    private func loadPOIs() async {
        do {
            let list = try await FirestoreService.shared.fetchPOIList()
            await MainActor.run {
                self.pois = list
            }
        } catch {
            // Handle error
        }
    }
    
    private func calculateRouteTime() {
        routeTimeInfo = RouteCalculator.shared.calculateTotalRouteTime(route: route, pois: pois)
    }
    
    private func updateProgress() {
        guard !route.stops.isEmpty else { return }
        routeProgress = Double(currentStepIndex) / Double(route.stops.count - 1)
        
        // Check if route is completed
        if currentStepIndex >= route.stops.count - 1 {
            handleRouteCompletion()
        }
    }
    
    private func handleRouteCompletion() {
        Task {
            await gamificationService.handleRouteCompletion(route.id)
        }
    }
    
    private func startRoute() {
        // Navigate to map with route active
        // This would typically involve navigation to MapScreen with route selected
    }
}

struct RouteHeaderView: View {
    let route: Route
    let timeInfo: RouteTimeInfo?
    
    var body: some View {
        VStack(spacing: 16) {
            // Route image placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 150)
                .overlay(
                    VStack {
                        Image(systemName: "map.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        Text("Маршрут")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
            
            VStack(spacing: 8) {
                Text(route.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                if let description = route.description {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Route stats
                if let timeInfo = timeInfo {
                    HStack(spacing: 20) {
                        RouteStatItem(
                            icon: "clock",
                            title: "Время",
                            value: timeInfo.formattedTotalTime
                        )
                        
                        RouteStatItem(
                            icon: "figure.walk",
                            title: "Ходьба",
                            value: timeInfo.formattedWalkingTime
                        )
                        
                        RouteStatItem(
                            icon: "location",
                            title: "Расстояние",
                            value: timeInfo.formattedDistance
                        )
                    }
                }
                
                // Route tags
                if let tags = route.tags, !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
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
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }
}

struct RouteStatItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.red)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

struct RouteProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    let progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Прогресс")
                    .font(.headline)
                Spacer()
                Text("\(currentStep + 1) из \(totalSteps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .red))
            
            Text("\(Int(progress * 100))% завершено")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct RouteStepsView: View {
    let route: Route
    let pois: [POI]
    @Binding var currentStepIndex: Int
    
    let onStepTap: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(route.stops.enumerated()), id: \.offset) { index, stop in
                RouteStepView(
                    step: stop,
                    poi: findPOI(for: stop.poiId),
                    isCurrent: index == currentStepIndex,
                    isCompleted: index < currentStepIndex,
                    stepNumber: index + 1,
                    onTap: { onStepTap(index) }
                )
                
                if index < route.stops.count - 1 {
                    // Connection line
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 20)
                        .padding(.leading, 25)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private func findPOI(for poiId: String) -> POI? {
        return pois.first { $0.id == poiId }
    }
}

struct RouteStepView: View {
    let step: RouteStop
    let poi: POI?
    let isCurrent: Bool
    let isCompleted: Bool
    let stepNumber: Int
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Step number circle
            ZStack {
                Circle()
                    .fill(stepCircleColor)
                    .frame(width: 32, height: 32)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(stepNumber)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(stepTextColor)
                }
            }
            
            // POI info
            VStack(alignment: .leading, spacing: 4) {
                Text(poi?.title ?? "Неизвестная точка")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isCurrent ? .primary : .secondary)
                
                if let note = step.note {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let dwellMin = step.dwellMin {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("\(dwellMin) мин")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Navigation arrow
            if isCurrent {
                Image(systemName: "location.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(isCurrent ? Color.red.opacity(0.1) : Color.clear)
        .cornerRadius(12)
        .onTapGesture {
            onTap()
        }
    }
    
    private var stepCircleColor: Color {
        if isCompleted {
            return .green
        } else if isCurrent {
            return .red
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private var stepTextColor: Color {
        if isCompleted {
            return .white
        } else if isCurrent {
            return .white
        } else {
            return .primary
        }
    }
}

struct RouteActionButtonsView: View {
    let route: Route
    let onShare: () -> Void
    let onCustomize: () -> Void
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Start route button
            Button(action: onStart) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Начать маршрут")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            // Secondary actions
            HStack(spacing: 12) {
                Button(action: onCustomize) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Настроить")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                
                Button(action: onShare) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Поделиться")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
        }
        .padding(16)
    }
}

struct RouteShareSheet: View {
    let route: Route
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("Поделиться маршрутом")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(route.title)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Share options
                VStack(spacing: 12) {
                    ShareOptionButton(
                        icon: "message",
                        title: "Сообщение",
                        action: shareViaMessage
                    )
                    
                    ShareOptionButton(
                        icon: "envelope",
                        title: "Email",
                        action: shareViaEmail
                    )
                    
                    ShareOptionButton(
                        icon: "link",
                        title: "Скопировать ссылку",
                        action: copyLink
                    )
                }
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Поделиться")
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
    
    private func shareViaMessage() {
        // TODO: Implement message sharing
        dismiss()
    }
    
    private func shareViaEmail() {
        // TODO: Implement email sharing
        dismiss()
    }
    
    private func copyLink() {
        // TODO: Implement link copying
        dismiss()
    }
}

struct ShareOptionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.red)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RouteCustomizationSheet: View {
    let route: Route
    @Environment(\.dismiss) private var dismiss
    @StateObject private var routeBuilder = RouteBuilderService.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Настройка маршрута")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Здесь можно настроить параметры маршрута")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Button("Закрыть") {
                    dismiss()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(24)
            .navigationTitle("Настройка")
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