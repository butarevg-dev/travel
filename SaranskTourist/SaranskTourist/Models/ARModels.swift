import Foundation
import ARKit
import SceneKit

// MARK: - AR Modes
enum ARMode: String, CaseIterable, Codable {
    case none = "none"
    case poiDetection = "poi_detection"
    case navigation = "navigation"
    case quest = "quest"
    case audio = "audio"
}

// MARK: - AR POI
struct ARPOI: Identifiable {
    let id: String
    let poi: POI
    let anchor: ARAnchor
    let distance: Float
    let isVisible: Bool
    let arInfo: ARPOIInfo
}

// MARK: - AR POI Information
struct ARPOIInfo: Codable {
    let title: String
    let description: String
    let audioURL: String?
    let hasAudio: Bool
    let rating: Double
    let categories: [String]
    let workingHours: String?
    let ticket: String?
    
    init(from poi: POI) {
        self.title = poi.title
        self.description = poi.description
        self.audioURL = poi.audio.first
        self.hasAudio = !poi.audio.isEmpty
        self.rating = poi.rating
        self.categories = poi.categories
        self.workingHours = poi.openingHours
        self.ticket = poi.ticket
    }
}

// MARK: - AR Route
struct ARRoute {
    let route: Route
    let waypoints: [ARWaypoint]
    let currentWaypointIndex: Int
    let distanceToNext: Float
    let estimatedTime: TimeInterval
}

// MARK: - AR Waypoint
struct ARWaypoint {
    let poi: POI
    let anchor: ARAnchor
    let distance: Float
    let direction: Float
    let isCompleted: Bool
}

// MARK: - AR Quest
struct ARQuest: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let type: ARQuestType
    let requirements: ARQuestRequirements
    let reward: QuestReward
    let poiId: String?
    let routeId: String?
    var isCompleted: Bool = false
    var isStarted: Bool = false
    var progress: Int = 0
}

// MARK: - AR Quest Types
enum ARQuestType: String, Codable, CaseIterable {
    case photoPOI = "photo_poi"
    case visitPOI = "visit_poi"
    case followRoute = "follow_route"
    case takePhoto = "take_photo"
    case findHidden = "find_hidden"
    case arNavigation = "ar_navigation"
}

// MARK: - AR Quest Requirements
struct ARQuestRequirements: Codable {
    let poiIds: [String]?
    let routeIds: [String]?
    let photoCount: Int?
    let timeLimit: TimeInterval?
    let distance: Double?
    let arMode: ARMode?
    let specificPOIs: [String]?
    let specificRoutes: [String]?
}

// MARK: - AR Capabilities
struct ARCapabilities {
    var isARKitSupported: Bool = false
    var isImageTrackingSupported: Bool = false
    var isObjectScanningSupported: Bool = false
    var isFaceTrackingSupported: Bool = false
    var devicePerformance: ARDevicePerformance = .unknown
    var maxImageTracking: Int = 0
    var supportsWorldTracking: Bool = false
    var supportsPlaneDetection: Bool = false
}

// MARK: - AR Device Performance
enum ARDevicePerformance: String, Codable {
    case excellent = "excellent"
    case good = "good"
    case poor = "poor"
    case unknown = "unknown"
}

// MARK: - AR Performance Metrics
struct ARPerformanceMetrics {
    let frameRate: Double
    let trackingQuality: ARTrackingState
    let batteryUsage: Double
    let memoryUsage: Double
    let sessionDuration: TimeInterval
    let detectedAnchors: Int
    let userInteractions: Int
    let timestamp: Date
}

// MARK: - AR Event
struct AREvent: Codable {
    let type: AREventType
    let timestamp: Date
    let poiId: String?
    let routeId: String?
    let questId: String?
    let metadata: [String: String]
}

// MARK: - AR Event Types
enum AREventType: String, Codable, CaseIterable {
    case sessionStarted = "session_started"
    case sessionEnded = "session_ended"
    case poiDetected = "poi_detected"
    case poiVisited = "poi_visited"
    case photoTaken = "photo_taken"
    case questStarted = "quest_started"
    case questCompleted = "quest_completed"
    case navigationStarted = "navigation_started"
    case navigationCompleted = "navigation_completed"
    case audioPlayed = "audio_played"
    case error = "error"
}

// MARK: - AR Configuration
struct ARConfiguration {
    let mode: ARMode
    let enableImageTracking: Bool
    let enablePlaneDetection: Bool
    let enableWorldTracking: Bool
    let maxImageTracking: Int
    let enableLighting: Bool
    let enablePhysics: Bool
}

// MARK: - AR Image Anchor
struct ARImageAnchorData: Codable {
    let id: String
    let name: String
    let physicalSize: CGSize
    let poiId: String?
    let imageURL: String?
}

// MARK: - AR Navigation State
struct ARNavigationState {
    let isActive: Bool
    let currentRoute: ARRoute?
    let nextWaypoint: ARWaypoint?
    let distanceToNext: Float
    let direction: Float
    let estimatedTime: TimeInterval
    let turnByTurnInstructions: [String]
}

// MARK: - AR Audio State
struct ARAudioState {
    let isPlaying: Bool
    let currentPOI: POI?
    let audioURL: String?
    let volume: Float
    let isSpatial: Bool
    let position: SCNVector3?
}

// MARK: - AR UI State
struct ARUIState {
    let showPOICards: Bool
    let showNavigationElements: Bool
    let showControls: Bool
    let showInfoPanel: Bool
    let selectedPOI: ARPOI?
    let activeQuests: [ARQuest]
}

// MARK: - AR Session State
struct ARSessionState {
    let isActive: Bool
    let trackingState: ARTrackingState
    let cameraTransform: simd_float4x4?
    let detectedPOIs: [ARPOI]
    let error: String?
    let capabilities: ARCapabilities
}

// MARK: - AR Statistics
struct ARStatistics: Codable {
    let totalSessions: Int
    let totalSessionTime: TimeInterval
    let totalPOIsDetected: Int
    let totalPOIsVisited: Int
    let totalPhotosTaken: Int
    let totalQuestsCompleted: Int
    let totalNavigationSessions: Int
    let averageSessionDuration: TimeInterval
    let mostVisitedPOI: String?
    let favoriteARMode: ARMode?
    let lastSessionDate: Date?
}

// MARK: - AR Settings
struct ARSettings: Codable {
    let enableImageTracking: Bool
    let enablePlaneDetection: Bool
    let enableWorldTracking: Bool
    let maxImageTracking: Int
    let enableLighting: Bool
    let enablePhysics: Bool
    let enableSpatialAudio: Bool
    let enableHapticFeedback: Bool
    let enableVoiceCommands: Bool
    let autoPlayAudio: Bool
    let showDistanceIndicators: Bool
    let showTurnByTurn: Bool
    let preferredARMode: ARMode
    let performanceMode: ARPerformanceMode
}

// MARK: - AR Performance Mode
enum ARPerformanceMode: String, Codable, CaseIterable {
    case high = "high"
    case balanced = "balanced"
    case low = "low"
    case battery = "battery"
}

// MARK: - AR Error
enum ARError: LocalizedError {
    case deviceNotSupported
    case cameraPermissionDenied
    case sessionConfigurationFailed
    case trackingLost
    case imageTrackingFailed
    case audioPlaybackFailed
    case navigationFailed
    case questNotFound
    case poiNotFound
    case routeNotFound
    
    var errorDescription: String? {
        switch self {
        case .deviceNotSupported:
            return "Устройство не поддерживает AR"
        case .cameraPermissionDenied:
            return "Нет разрешения на использование камеры"
        case .sessionConfigurationFailed:
            return "Не удалось настроить AR сессию"
        case .trackingLost:
            return "Потеряно отслеживание AR"
        case .imageTrackingFailed:
            return "Не удалось распознать изображение"
        case .audioPlaybackFailed:
            return "Ошибка воспроизведения аудио"
        case .navigationFailed:
            return "Ошибка AR навигации"
        case .questNotFound:
            return "Квест не найден"
        case .poiNotFound:
            return "Точка интереса не найдена"
        case .routeNotFound:
            return "Маршрут не найден"
        }
    }
}

// MARK: - AR Extensions
extension ARPOI {
    var distanceString: String {
        if distance < 1 {
            return "\(Int(distance * 100)) см"
        } else {
            return String(format: "%.1f м", distance)
        }
    }
    
    var isNearby: Bool {
        return distance < 5.0 // 5 метров
    }
    
    var isInRange: Bool {
        return distance < 20.0 // 20 метров
    }
}

extension ARWaypoint {
    var directionString: String {
        let degrees = direction * 180 / .pi
        if degrees >= -22.5 && degrees < 22.5 {
            return "вперед"
        } else if degrees >= 22.5 && degrees < 67.5 {
            return "вперед-направо"
        } else if degrees >= 67.5 && degrees < 112.5 {
            return "направо"
        } else if degrees >= 112.5 && degrees < 157.5 {
            return "назад-направо"
        } else if degrees >= 157.5 || degrees < -157.5 {
            return "назад"
        } else if degrees >= -157.5 && degrees < -112.5 {
            return "назад-налево"
        } else if degrees >= -112.5 && degrees < -67.5 {
            return "налево"
        } else {
            return "вперед-налево"
        }
    }
}

extension ARQuest {
    var isAvailable: Bool {
        return !isStarted && !isCompleted
    }
    
    var progressPercentage: Double {
        guard let photoCount = requirements.photoCount, photoCount > 0 else {
            return isCompleted ? 1.0 : 0.0
        }
        return Double(progress) / Double(photoCount)
    }
    
    var estimatedTimeString: String {
        guard let timeLimit = requirements.timeLimit else {
            return "Без ограничений"
        }
        let minutes = Int(timeLimit / 60)
        return "\(minutes) мин"
    }
}

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

enum ARSupportLevel: String {
    case full = "full"
    case partial = "partial"
    case none = "none"
}