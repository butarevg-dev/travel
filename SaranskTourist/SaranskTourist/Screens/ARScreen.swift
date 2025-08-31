import SwiftUI
import ARKit
import SceneKit

struct ARScreen: View {
    @StateObject private var arService = ARService.shared
    @StateObject private var compatibilityChecker = ARCompatibilityChecker.shared
    @StateObject private var gamificationService = GamificationService.shared
    @State private var selectedARMode: ARMode = .poiDetection
    @State private var showingModeSelector = false
    @State private var showingFallbackView = false
    @State private var showingSettings = false
    
    var body: some View {
        Group {
            if compatibilityChecker.supportLevel == .none {
                ARFallbackView(
                    capabilities: compatibilityChecker.capabilities,
                    onRetry: {
                        compatibilityChecker.checkCapabilities()
                    }
                )
            } else {
                ARMainView()
            }
        }
        .onAppear {
            checkARCompatibility()
        }
    }
    
    private func checkARCompatibility() {
        if compatibilityChecker.supportLevel == .none {
            showingFallbackView = true
        }
    }
}

// MARK: - AR Main View
struct ARMainView: View {
    @StateObject private var arService = ARService.shared
    @State private var selectedARMode: ARMode = .poiDetection
    @State private var showingModeSelector = false
    @State private var showingSettings = false
    
    var body: some View {
        ZStack {
            // AR View
            ARViewRepresentable()
                .ignoresSafeArea()
            
            // AR Overlays
            VStack {
                // Top Controls
                ARTopControls(
                    selectedMode: $selectedARMode,
                    showingModeSelector: $showingModeSelector,
                    showingSettings: $showingSettings
                )
                
                Spacer()
                
                // Bottom Controls
                ARBottomControls()
            }
            
            // POI Information Cards
            if arService.uiState.showPOICards {
                ARPOICards()
            }
            
            // Navigation Elements
            if arService.uiState.showNavigationElements {
                ARNavigationElements()
            }
            
            // Error Overlay
            if let error = arService.error {
                ARErrorOverlay(error: error)
            }
        }
        .onAppear {
            arService.startARSession(mode: selectedARMode)
        }
        .onDisappear {
            arService.stopARSession()
        }
        .sheet(isPresented: $showingModeSelector) {
            ARModeSelectorView(selectedMode: $selectedARMode)
        }
        .sheet(isPresented: $showingSettings) {
            ARSettingsView()
        }
    }
}

// MARK: - AR View Representable
struct ARViewRepresentable: UIViewRepresentable {
    @StateObject private var arService = ARService.shared
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.delegate = context.coordinator
        arView.session.delegate = context.coordinator
        arView.automaticallyUpdatesLighting = true
        arView.autoenablesDefaultLighting = true
        arView.showsStatistics = false
        arView.debugOptions = []
        
        arService.setARView(arView)
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Обновление AR конфигурации при необходимости
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        var parent: ARViewRepresentable
        
        init(_ parent: ARViewRepresentable) {
            self.parent = parent
        }
        
        // AR делегаты будут обрабатываться в ARService
    }
}

// MARK: - AR Top Controls
struct ARTopControls: View {
    @Binding var selectedMode: ARMode
    @Binding var showingModeSelector: Bool
    @Binding var showingSettings: Bool
    @StateObject private var arService = ARService.shared
    
    var body: some View {
        HStack {
            // Mode Selector
            Button {
                showingModeSelector = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: getModeIcon(selectedMode))
                    Text(getModeTitle(selectedMode))
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }
            
            Spacer()
            
            // Settings Button
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .medium))
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
            }
            
            // Session Status
            ARSessionStatusIndicator()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private func getModeIcon(_ mode: ARMode) -> String {
        switch mode {
        case .none:
            return "camera.viewfinder"
        case .poiDetection:
            return "mappin.circle"
        case .navigation:
            return "location.north"
        case .quest:
            return "gamecontroller"
        case .audio:
            return "headphones"
        }
    }
    
    private func getModeTitle(_ mode: ARMode) -> String {
        switch mode {
        case .none:
            return "AR"
        case .poiDetection:
            return "Поиск POI"
        case .navigation:
            return "Навигация"
        case .quest:
            return "Квесты"
        case .audio:
            return "Аудио"
        }
    }
}

// MARK: - AR Bottom Controls
struct ARBottomControls: View {
    @StateObject private var arService = ARService.shared
    
    var body: some View {
        HStack(spacing: 20) {
            // Photo Button
            Button {
                takePhoto()
            } label: {
                Image(systemName: "camera.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.red)
                    .clipShape(Circle())
            }
            
            // Audio Button
            if arService.audioState.isPlaying {
                Button {
                    stopAudio()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            } else {
                Button {
                    playAudio()
                } label: {
                    Image(systemName: "headphones")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
            
            // Info Button
            Button {
                toggleInfoPanel()
            } label: {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.green)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 30)
    }
    
    private func takePhoto() {
        // Фотографирование в AR
        if let selectedPOI = arService.uiState.selectedPOI {
            Task {
                await arService.handleARPhotoCapture(selectedPOI.poi)
            }
        }
    }
    
    private func playAudio() {
        // Воспроизведение аудио
        if let selectedPOI = arService.uiState.selectedPOI {
            arService.playSpatialAudio(for: selectedPOI.poi)
        }
    }
    
    private func stopAudio() {
        // Остановка аудио
        arService.audioService.stop()
    }
    
    private func toggleInfoPanel() {
        arService.uiState.showInfoPanel.toggle()
    }
}

// MARK: - AR POI Cards
struct ARPOICards: View {
    @StateObject private var arService = ARService.shared
    
    var body: some View {
        VStack {
            ForEach(arService.detectedPOIs) { arPOI in
                ARPOICard(arPOI: arPOI)
                    .onTapGesture {
                        arService.uiState.selectedPOI = arPOI
                    }
            }
        }
        .padding(.horizontal, 16)
    }
}

struct ARPOICard: View {
    let arPOI: ARPOI
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(arPOI.poi.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(arPOI.distanceString)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text(arPOI.poi.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(2)
            
            HStack {
                ForEach(arPOI.poi.categories, id: \.self) { category in
                    Text(category)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                if arPOI.poi.audio.count > 0 {
                    Image(systemName: "headphones")
                        .foregroundColor(.white)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

// MARK: - AR Navigation Elements
struct ARNavigationElements: View {
    @StateObject private var arService = ARService.shared
    
    var body: some View {
        VStack {
            if let navigationState = arService.navigationState,
               navigationState.isActive {
                ARNavigationPanel(navigationState: navigationState)
            }
        }
        .padding(.horizontal, 16)
    }
}

struct ARNavigationPanel: View {
    let navigationState: ARNavigationState
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Навигация")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(String(format: "%.0f м", navigationState.distanceToNext))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            if let nextWaypoint = navigationState.nextWaypoint {
                Text("Следующая точка: \(nextWaypoint.poi.title)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                
                Text("Направление: \(nextWaypoint.directionString)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

// MARK: - AR Session Status Indicator
struct ARSessionStatusIndicator: View {
    @StateObject private var arService = ARService.shared
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(getStatusColor())
                .frame(width: 8, height: 8)
            
            Text(getStatusText())
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private func getStatusColor() -> Color {
        switch arService.sessionState.trackingState {
        case .normal:
            return .green
        case .limited:
            return .yellow
        case .notAvailable:
            return .red
        @unknown default:
            return .gray
        }
    }
    
    private func getStatusText() -> String {
        switch arService.sessionState.trackingState {
        case .normal:
            return "AR"
        case .limited:
            return "Ограничено"
        case .notAvailable:
            return "Недоступно"
        @unknown default:
            return "Неизвестно"
        }
    }
}

// MARK: - AR Error Overlay
struct ARErrorOverlay: View {
    let error: String
    @StateObject private var arService = ARService.shared
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                
                Text(error)
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("OK") {
                    arService.error = nil
                }
                .font(.caption)
                .foregroundColor(.white)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - AR Mode Selector
struct ARModeSelectorView: View {
    @Binding var selectedMode: ARMode
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(ARMode.allCases, id: \.self) { mode in
                Button {
                    selectedMode = mode
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: getModeIcon(mode))
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading) {
                            Text(getModeTitle(mode))
                                .font(.headline)
                            Text(getModeDescription(mode))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedMode == mode {
                            Image(systemName: "checkmark")
                                .foregroundColor(.red)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Режим AR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getModeIcon(_ mode: ARMode) -> String {
        switch mode {
        case .none:
            return "camera.viewfinder"
        case .poiDetection:
            return "mappin.circle"
        case .navigation:
            return "location.north"
        case .quest:
            return "gamecontroller"
        case .audio:
            return "headphones"
        }
    }
    
    private func getModeTitle(_ mode: ARMode) -> String {
        switch mode {
        case .none:
            return "Базовый AR"
        case .poiDetection:
            return "Поиск достопримечательностей"
        case .navigation:
            return "AR навигация"
        case .quest:
            return "AR квесты"
        case .audio:
            return "Пространственное аудио"
        }
    }
    
    private func getModeDescription(_ mode: ARMode) -> String {
        switch mode {
        case .none:
            return "Базовый режим AR без специальных функций"
        case .poiDetection:
            return "Распознавание и отображение достопримечательностей"
        case .navigation:
            return "Навигация по маршрутам в AR"
        case .quest:
            return "Выполнение квестов в AR"
        case .audio:
            return "Пространственное воспроизведение аудиогидов"
        }
    }
}

// MARK: - AR Settings View
struct ARSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var arService = ARService.shared
    @StateObject private var compatibilityChecker = ARCompatibilityChecker.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section("Производительность") {
                    HStack {
                        Text("Уровень поддержки")
                        Spacer()
                        Text(compatibilityChecker.supportLevel.rawValue.capitalized)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Производительность устройства")
                        Spacer()
                        Text(compatibilityChecker.capabilities.devicePerformance.rawValue.capitalized)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Рекомендации") {
                    ForEach(compatibilityChecker.getPerformanceRecommendations(), id: \.self) { recommendation in
                        Text(getRecommendationText(recommendation))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Альтернативы") {
                    ForEach(compatibilityChecker.getFallbackOptions(), id: \.self) { option in
                        Button(getFallbackOptionText(option)) {
                            // Обработка выбора альтернативы
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Настройки AR")
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
    
    private func getRecommendationText(_ recommendation: ARPerformanceRecommendation) -> String {
        switch recommendation {
        case .enableAllFeatures:
            return "Включить все функции AR"
        case .enableCoreFeatures:
            return "Включить основные функции AR"
        case .enableBasicFeatures:
            return "Включить базовые функции AR"
        case .highQualityRendering:
            return "Высокое качество рендеринга"
        case .balancedRendering:
            return "Сбалансированное качество рендеринга"
        case .lowQualityRendering:
            return "Низкое качество рендеринга"
        case .enableEnvironmentTexturing:
            return "Включить текстурирование окружения"
        case .disableEnvironmentTexturing:
            return "Отключить текстурирование окружения"
        case .limitImageTracking:
            return "Ограничить отслеживание изображений"
        case .singleImageTracking:
            return "Отслеживание одного изображения"
        }
    }
    
    private func getFallbackOptionText(_ option: ARFallbackOption) -> String {
        switch option {
        case .useMapView:
            return "Использовать карту"
        case .usePhotoMode:
            return "Режим фотографий"
        case .useTextMode:
            return "Текстовый режим"
        case .useBasicAR:
            return "Базовый AR"
        case .useWorldTracking:
            return "Отслеживание мира"
        }
    }
}