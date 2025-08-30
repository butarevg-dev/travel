import Foundation
import ARKit
import UIKit

class ARCompatibilityChecker: ObservableObject {
    static let shared = ARCompatibilityChecker()
    
    @Published var capabilities = ARCapabilities()
    @Published var supportLevel: ARSupportLevel = .unknown
    @Published var isChecking = false
    
    private init() {
        checkCapabilities()
    }
    
    // MARK: - Capability Checking
    func checkCapabilities() {
        isChecking = true
        
        var newCapabilities = ARCapabilities()
        
        // Проверка поддержки ARKit
        newCapabilities.isARKitSupported = ARWorldTrackingConfiguration.isSupported
        
        // Проверка поддержки image tracking
        newCapabilities.isImageTrackingSupported = ARImageTrackingConfiguration.isSupported
        
        // Проверка поддержки object scanning
        newCapabilities.isObjectScanningSupported = ARObjectScanningConfiguration.isSupported
        
        // Проверка поддержки face tracking
        newCapabilities.isFaceTrackingSupported = ARFaceTrackingConfiguration.isSupported
        
        // Проверка поддержки world tracking
        newCapabilities.supportsWorldTracking = ARWorldTrackingConfiguration.isSupported
        
        // Проверка поддержки plane detection
        newCapabilities.supportsPlaneDetection = true
        
        // Определение максимального количества отслеживаемых изображений
        newCapabilities.maxImageTracking = determineMaxImageTracking()
        
        // Определение производительности устройства
        newCapabilities.devicePerformance = determineDevicePerformance()
        
        capabilities = newCapabilities
        supportLevel = determineSupportLevel(capabilities: newCapabilities)
        isChecking = false
    }
    
    // MARK: - Support Level Determination
    private func determineSupportLevel(capabilities: ARCapabilities) -> ARSupportLevel {
        if capabilities.isFullySupported {
            return .full
        } else if capabilities.isPartiallySupported {
            return .partial
        } else {
            return .none
        }
    }
    
    // MARK: - Device Performance Assessment
    private func determineDevicePerformance() -> ARDevicePerformance {
        let device = UIDevice.current
        
        // Проверка модели устройства
        let model = device.model
        let systemVersion = device.systemVersion
        
        // Определение по количеству процессоров
        let processorCount = ProcessInfo.processInfo.processorCount
        
        // Определение по доступной памяти
        let memorySize = ProcessInfo.processInfo.physicalMemory
        let memoryGB = memorySize / (1024 * 1024 * 1024)
        
        // Определение по версии iOS
        let iosVersion = Float(systemVersion) ?? 0
        
        // Логика определения производительности
        if processorCount >= 6 && memoryGB >= 4 && iosVersion >= 13.0 {
            return .excellent
        } else if processorCount >= 4 && memoryGB >= 2 && iosVersion >= 12.0 {
            return .good
        } else if processorCount >= 2 && memoryGB >= 1 && iosVersion >= 11.0 {
            return .poor
        } else {
            return .unknown
        }
    }
    
    // MARK: - Image Tracking Capacity
    private func determineMaxImageTracking() -> Int {
        let device = UIDevice.current
        let model = device.model
        
        // Определение максимального количества отслеживаемых изображений
        // в зависимости от производительности устройства
        switch determineDevicePerformance() {
        case .excellent:
            return 4
        case .good:
            return 2
        case .poor:
            return 1
        case .unknown:
            return 1
        }
    }
    
    // MARK: - Feature Availability
    func isFeatureAvailable(_ feature: ARFeature) -> Bool {
        switch feature {
        case .worldTracking:
            return capabilities.supportsWorldTracking
        case .imageTracking:
            return capabilities.isImageTrackingSupported
        case .planeDetection:
            return capabilities.supportsPlaneDetection
        case .objectScanning:
            return capabilities.isObjectScanningSupported
        case .faceTracking:
            return capabilities.isFaceTrackingSupported
        case .lightEstimation:
            return capabilities.isARKitSupported
        case .environmentTexturing:
            return capabilities.isARKitSupported && capabilities.devicePerformance != .poor
        }
    }
    
    // MARK: - Performance Recommendations
    func getPerformanceRecommendations() -> [ARPerformanceRecommendation] {
        var recommendations: [ARPerformanceRecommendation] = []
        
        switch capabilities.devicePerformance {
        case .excellent:
            recommendations.append(.enableAllFeatures)
            recommendations.append(.highQualityRendering)
            recommendations.append(.enableEnvironmentTexturing)
        case .good:
            recommendations.append(.enableCoreFeatures)
            recommendations.append(.balancedRendering)
            recommendations.append(.limitImageTracking)
        case .poor:
            recommendations.append(.enableBasicFeatures)
            recommendations.append(.lowQualityRendering)
            recommendations.append(.singleImageTracking)
            recommendations.append(.disableEnvironmentTexturing)
        case .unknown:
            recommendations.append(.enableBasicFeatures)
            recommendations.append(.lowQualityRendering)
        }
        
        return recommendations
    }
    
    // MARK: - Fallback Options
    func getFallbackOptions() -> [ARFallbackOption] {
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
    
    // MARK: - Configuration Generation
    func generateARConfiguration(for mode: ARMode) -> ARConfiguration? {
        guard capabilities.isARKitSupported else { return nil }
        
        let configuration = ARWorldTrackingConfiguration()
        
        // Базовая настройка
        configuration.isLightEstimationEnabled = isFeatureAvailable(.lightEstimation)
        
        // Настройка plane detection
        if isFeatureAvailable(.planeDetection) {
            configuration.planeDetection = [.horizontal, .vertical]
        }
        
        // Настройка environment texturing
        if isFeatureAvailable(.environmentTexturing) {
            configuration.environmentTexturing = .automatic
        }
        
        // Настройка image tracking
        if mode == .poiDetection || mode == .quest {
            if isFeatureAvailable(.imageTracking) {
                // Image tracking будет настроен позже
            }
        }
        
        return configuration
    }
    
    // MARK: - User Guidance
    func getUserGuidance() -> ARUserGuidance {
        switch supportLevel {
        case .full:
            return ARUserGuidance(
                title: "AR полностью поддерживается",
                message: "Ваше устройство поддерживает все функции AR. Наслаждайтесь полным опытом!",
                recommendations: [
                    "Используйте в хорошо освещенном месте",
                    "Держите устройство стабильно",
                    "Избегайте быстрых движений"
                ],
                canUseAR: true
            )
        case .partial:
            return ARUserGuidance(
                title: "AR частично поддерживается",
                message: "Некоторые функции AR могут работать медленнее или быть недоступны.",
                recommendations: [
                    "Используйте в хорошо освещенном месте",
                    "Держите устройство стабильно",
                    "Рассмотрите использование карты как альтернативу"
                ],
                canUseAR: true
            )
        case .none:
            return ARUserGuidance(
                title: "AR не поддерживается",
                message: "Ваше устройство не поддерживает AR. Используйте карту для навигации.",
                recommendations: [
                    "Используйте карту для поиска достопримечательностей",
                    "Просматривайте фотографии и описания",
                    "Слушайте аудиогиды"
                ],
                canUseAR: false
            )
        case .unknown:
            return ARUserGuidance(
                title: "AR статус неизвестен",
                message: "Не удалось определить поддержку AR. Попробуйте использовать карту.",
                recommendations: [
                    "Попробуйте перезапустить приложение",
                    "Используйте карту как альтернативу",
                    "Обратитесь в поддержку"
                ],
                canUseAR: false
            )
        }
    }
}

// MARK: - Supporting Types
enum ARFeature {
    case worldTracking
    case imageTracking
    case planeDetection
    case objectScanning
    case faceTracking
    case lightEstimation
    case environmentTexturing
}

enum ARPerformanceRecommendation {
    case enableAllFeatures
    case enableCoreFeatures
    case enableBasicFeatures
    case highQualityRendering
    case balancedRendering
    case lowQualityRendering
    case enableEnvironmentTexturing
    case disableEnvironmentTexturing
    case limitImageTracking
    case singleImageTracking
}

enum ARFallbackOption {
    case useMapView
    case usePhotoMode
    case useTextMode
    case useBasicAR
    case useWorldTracking
}

struct ARUserGuidance {
    let title: String
    let message: String
    let recommendations: [String]
    let canUseAR: Bool
}

// MARK: - Extensions
extension ARCapabilities {
    var isFullySupported: Bool {
        return isARKitSupported && isImageTrackingSupported && supportsWorldTracking
    }
    
    var isPartiallySupported: Bool {
        return isARKitSupported && (isImageTrackingSupported || supportsWorldTracking)
    }
    
    var supportLevel: ARSupportLevel {
        if isFullySupported {
            return .full
        } else if isPartiallySupported {
            return .partial
        } else {
            return .none
        }
    }
}

enum ARSupportLevel: String, CaseIterable {
    case full = "full"
    case partial = "partial"
    case none = "none"
    case unknown = "unknown"
}