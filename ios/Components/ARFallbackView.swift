import SwiftUI

struct ARFallbackView: View {
    let capabilities: ARCapabilities
    let onRetry: () -> Void
    @StateObject private var gamificationService = GamificationService.shared
    @State private var selectedFallbackOption: ARFallbackOption = .useMapView
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 64))
                        .foregroundColor(.red)
                    
                    Text("AR недоступно")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(getFallbackMessage())
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                }
                
                // Capabilities Info
                if capabilities.isPartiallySupported {
                    VStack(spacing: 12) {
                        Text("Возможности вашего устройства:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            CapabilityRow(
                                title: "ARKit",
                                isSupported: capabilities.isARKitSupported,
                                description: "Базовая поддержка AR"
                            )
                            
                            CapabilityRow(
                                title: "Отслеживание изображений",
                                isSupported: capabilities.isImageTrackingSupported,
                                description: "Распознавание табличек и фото"
                            )
                            
                            CapabilityRow(
                                title: "Отслеживание мира",
                                isSupported: capabilities.supportsWorldTracking,
                                description: "Позиционирование в пространстве"
                            )
                            
                            CapabilityRow(
                                title: "Обнаружение плоскостей",
                                isSupported: capabilities.supportsPlaneDetection,
                                description: "Определение поверхностей"
                            )
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                }
                
                // Performance Info
                VStack(spacing: 12) {
                    Text("Производительность:")
                        .font(.headline)
                    
                    HStack {
                        Text("Уровень:")
                        Spacer()
                        Text(capabilities.devicePerformance.rawValue.capitalized)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Text("Макс. изображений:")
                        Spacer()
                        Text("\(capabilities.maxImageTracking)")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                
                // Alternative Options
                VStack(spacing: 16) {
                    Text("Альтернативные способы использования:")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        ForEach(getAvailableFallbackOptions(), id: \.self) { option in
                            FallbackOptionButton(
                                option: option,
                                isSelected: selectedFallbackOption == option,
                                onTap: {
                                    selectedFallbackOption = option
                                    handleFallbackOption(option)
                                }
                            )
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Попробовать снова") {
                        onRetry()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Перейти к карте") {
                        handleFallbackOption(.useMapView)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("AR недоступно")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func getFallbackMessage() -> String {
        if !capabilities.isARKitSupported {
            return "Ваше устройство не поддерживает AR. Используйте карту для навигации и поиска достопримечательностей."
        } else if capabilities.devicePerformance == .poor {
            return "Производительность AR может быть низкой. Попробуйте в хорошо освещенном месте или используйте альтернативные функции."
        } else if !capabilities.isImageTrackingSupported {
            return "Отслеживание изображений недоступно, но другие функции AR могут работать."
        } else {
            return "AR временно недоступно. Проверьте освещение и попробуйте снова."
        }
    }
    
    private func getAvailableFallbackOptions() -> [ARFallbackOption] {
        var options: [ARFallbackOption] = []
        
        if !capabilities.isARKitSupported {
            options.append(.useMapView)
            options.append(.usePhotoMode)
            options.append(.useTextMode)
        } else if capabilities.devicePerformance == .poor {
            options.append(.useBasicAR)
            options.append(.useMapView)
            options.append(.usePhotoMode)
        } else if !capabilities.isImageTrackingSupported {
            options.append(.useWorldTracking)
            options.append(.useMapView)
        }
        
        return options
    }
    
    private func handleFallbackOption(_ option: ARFallbackOption) {
        switch option {
        case .useMapView:
            // Навигация к карте
            navigateToMap()
        case .usePhotoMode:
            // Открытие режима фотографий
            openPhotoMode()
        case .useTextMode:
            // Открытие текстового режима
            openTextMode()
        case .useBasicAR:
            // Попытка запуска базового AR
            tryBasicAR()
        case .useWorldTracking:
            // Использование только world tracking
            useWorldTrackingOnly()
        }
    }
    
    private func navigateToMap() {
        // Навигация к карте
        // Здесь будет интеграция с навигацией приложения
    }
    
    private func openPhotoMode() {
        // Открытие режима фотографий
        // Здесь будет интеграция с камерой
    }
    
    private func openTextMode() {
        // Открытие текстового режима
        // Здесь будет интеграция с текстовым интерфейсом
    }
    
    private func tryBasicAR() {
        // Попытка запуска базового AR
        // Здесь будет попытка запуска AR с ограниченными функциями
    }
    
    private func useWorldTrackingOnly() {
        // Использование только world tracking
        // Здесь будет запуск AR без image tracking
    }
}

// MARK: - Supporting Views
struct CapabilityRow: View {
    let title: String
    let isSupported: Bool
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isSupported ? .green : .red)
        }
    }
}

struct FallbackOptionButton: View {
    let option: ARFallbackOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: getOptionIcon(option))
                    .foregroundColor(isSelected ? .white : .red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(getOptionTitle(option))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(getOptionDescription(option))
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.red : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func getOptionIcon(_ option: ARFallbackOption) -> String {
        switch option {
        case .useMapView:
            return "map"
        case .usePhotoMode:
            return "camera"
        case .useTextMode:
            return "text.alignleft"
        case .useBasicAR:
            return "camera.viewfinder"
        case .useWorldTracking:
            return "location.north"
        }
    }
    
    private func getOptionTitle(_ option: ARFallbackOption) -> String {
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
    
    private func getOptionDescription(_ option: ARFallbackOption) -> String {
        switch option {
        case .useMapView:
            return "Навигация по карте с поиском достопримечательностей"
        case .usePhotoMode:
            return "Фотографирование достопримечательностей"
        case .useTextMode:
            return "Просмотр информации в текстовом виде"
        case .useBasicAR:
            return "AR с ограниченными функциями"
        case .useWorldTracking:
            return "AR без распознавания изображений"
        }
    }
}

// MARK: - AR Fallback Navigation
struct ARFallbackNavigationView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Map Tab
            MapFallbackView()
                .tabItem {
                    Label("Карта", systemImage: "map")
                }
                .tag(0)
            
            // Photo Tab
            PhotoFallbackView()
                .tabItem {
                    Label("Фото", systemImage: "camera")
                }
                .tag(1)
            
            // Text Tab
            TextFallbackView()
                .tabItem {
                    Label("Информация", systemImage: "text.alignleft")
                }
                .tag(2)
        }
    }
}

// MARK: - Fallback Tab Views
struct MapFallbackView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Карта")
                    .font(.title)
                    .padding()
                
                Text("Используйте карту для поиска достопримечательностей")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Карта")
        }
    }
}

struct PhotoFallbackView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Фотографии")
                    .font(.title)
                    .padding()
                
                Text("Фотографируйте достопримечательности")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Фото")
        }
    }
}

struct TextFallbackView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Информация")
                    .font(.title)
                    .padding()
                
                Text("Просматривайте информацию о достопримечательностях")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Информация")
        }
    }
}

// MARK: - Preview
struct ARFallbackView_Previews: PreviewProvider {
    static var previews: some View {
        ARFallbackView(
            capabilities: ARCapabilities(
                isARKitSupported: false,
                isImageTrackingSupported: false,
                isObjectScanningSupported: false,
                isFaceTrackingSupported: false,
                devicePerformance: .unknown,
                maxImageTracking: 0,
                supportsWorldTracking: false,
                supportsPlaneDetection: false
            ),
            onRetry: {}
        )
    }
}