import Foundation
import CoreLocation

class RouteBuilderService: ObservableObject {
    static let shared = RouteBuilderService()
    
    // MARK: - Published Properties
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    @Published var error: String?
    
    // MARK: - Private Properties
    private let routeCalculator = RouteCalculator.shared
    
    // MARK: - Route Generation Parameters
    struct RouteParameters {
        let interests: [String]
        let maxDuration: TimeInterval // in minutes
        let startLocation: CLLocationCoordinate2D?
        let preferredCategories: [String]
        let avoidCategories: [String]
        let maxDistance: Double // in kilometers
        let includeAudioGuides: Bool
        let includeRestaurants: Bool
        let includeShopping: Bool
    }
    
    // MARK: - Route Generation Result
    struct GeneratedRoute {
        let id: String
        let title: String
        let description: String
        let stops: [RouteStop]
        let polyline: [Coordinates]
        let totalDuration: TimeInterval
        let totalDistance: Double
        let interests: [String]
        let tags: [String]
        let estimatedCost: Double?
        let difficulty: RouteDifficulty
        let audioGuides: [String]
    }
    
    enum RouteDifficulty: String, CaseIterable {
        case easy = "easy"
        case medium = "medium"
        case hard = "hard"
        
        var displayName: String {
            switch self {
            case .easy: return "Легкий"
            case .medium: return "Средний"
            case .hard: return "Сложный"
            }
        }
        
        var icon: String {
            switch self {
            case .easy: return "figure.walk"
            case .medium: return "figure.hiking"
            case .hard: return "figure.climbing"
            }
        }
    }
    
    private init() {}
    
    // MARK: - Public Methods
    
    func generateCustomRoute(parameters: RouteParameters, pois: [POI]) async -> GeneratedRoute? {
        await MainActor.run {
            isGenerating = true
            generationProgress = 0.0
            error = nil
        }
        
        do {
            // Step 1: Filter POIs based on interests and preferences
            let filteredPOIs = filterPOIs(pois: pois, parameters: parameters)
            await updateProgress(0.2)
            
            // Step 2: Calculate optimal route
            let routeStops = calculateOptimalRoute(pois: filteredPOIs, parameters: parameters)
            await updateProgress(0.6)
            
            // Step 3: Generate polyline
            let polyline = generatePolyline(from: routeStops, startLocation: parameters.startLocation)
            await updateProgress(0.8)
            
            // Step 4: Calculate final metrics
            let metrics = calculateRouteMetrics(stops: routeStops, polyline: polyline)
            await updateProgress(1.0)
            
            // Step 5: Create route
            let route = createGeneratedRoute(
                stops: routeStops,
                polyline: polyline,
                metrics: metrics,
                parameters: parameters
            )
            
            await MainActor.run {
                isGenerating = false
                generationProgress = 0.0
            }
            
            return route
            
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isGenerating = false
                generationProgress = 0.0
            }
            return nil
        }
    }
    
    func generatePresetRoute(type: PresetRouteType, pois: [POI]) -> GeneratedRoute? {
        let parameters = type.parameters
        return generateCustomRoute(parameters: parameters, pois: pois)
    }
    
    // MARK: - Preset Route Types
    enum PresetRouteType: String, CaseIterable {
        case threeHours = "3h"
        case sixHours = "6h"
        case oneDay = "1d"
        case weekend = "weekend"
        case family = "family"
        case cultural = "cultural"
        case food = "food"
        case shopping = "shopping"
        
        var displayName: String {
            switch self {
            case .threeHours: return "3 часа"
            case .sixHours: return "6 часов"
            case .oneDay: return "1 день"
            case .weekend: return "Выходные"
            case .family: return "Семейный"
            case .cultural: return "Культурный"
            case .food: return "Гастрономический"
            case .shopping: return "Шоппинг"
            }
        }
        
        var icon: String {
            switch self {
            case .threeHours: return "clock"
            case .sixHours: return "clock.fill"
            case .oneDay: return "sun.max"
            case .weekend: return "calendar"
            case .family: return "person.3"
            case .cultural: return "building.columns"
            case .food: return "fork.knife"
            case .shopping: return "bag"
            }
        }
        
        var parameters: RouteBuilderService.RouteParameters {
            switch self {
            case .threeHours:
                return RouteParameters(
                    interests: ["архитектура", "история"],
                    maxDuration: 180,
                    startLocation: nil,
                    preferredCategories: ["архитектура", "история"],
                    avoidCategories: [],
                    maxDistance: 5.0,
                    includeAudioGuides: true,
                    includeRestaurants: false,
                    includeShopping: false
                )
            case .sixHours:
                return RouteParameters(
                    interests: ["архитектура", "история", "музеи"],
                    maxDuration: 360,
                    startLocation: nil,
                    preferredCategories: ["архитектура", "история", "музеи"],
                    avoidCategories: [],
                    maxDistance: 8.0,
                    includeAudioGuides: true,
                    includeRestaurants: true,
                    includeShopping: false
                )
            case .oneDay:
                return RouteParameters(
                    interests: ["архитектура", "история", "музеи", "развлечения"],
                    maxDuration: 480,
                    startLocation: nil,
                    preferredCategories: ["архитектура", "история", "музеи"],
                    avoidCategories: [],
                    maxDistance: 12.0,
                    includeAudioGuides: true,
                    includeRestaurants: true,
                    includeShopping: true
                )
            case .weekend:
                return RouteParameters(
                    interests: ["архитектура", "история", "музеи", "развлечения", "семейный"],
                    maxDuration: 960,
                    startLocation: nil,
                    preferredCategories: ["архитектура", "история", "музеи", "развлечения"],
                    avoidCategories: [],
                    maxDistance: 15.0,
                    includeAudioGuides: true,
                    includeRestaurants: true,
                    includeShopping: true
                )
            case .family:
                return RouteParameters(
                    interests: ["семейный", "развлечения", "музеи"],
                    maxDuration: 240,
                    startLocation: nil,
                    preferredCategories: ["семейный", "развлечения"],
                    avoidCategories: [],
                    maxDistance: 6.0,
                    includeAudioGuides: true,
                    includeRestaurants: true,
                    includeShopping: false
                )
            case .cultural:
                return RouteParameters(
                    interests: ["музеи", "история", "архитектура"],
                    maxDuration: 300,
                    startLocation: nil,
                    preferredCategories: ["музеи", "история"],
                    avoidCategories: ["еда", "развлечения"],
                    maxDistance: 7.0,
                    includeAudioGuides: true,
                    includeRestaurants: false,
                    includeShopping: false
                )
            case .food:
                return RouteParameters(
                    interests: ["еда", "развлечения"],
                    maxDuration: 180,
                    startLocation: nil,
                    preferredCategories: ["еда"],
                    avoidCategories: [],
                    maxDistance: 4.0,
                    includeAudioGuides: false,
                    includeRestaurants: true,
                    includeShopping: false
                )
            case .shopping:
                return RouteParameters(
                    interests: ["сувениры", "развлечения"],
                    maxDuration: 120,
                    startLocation: nil,
                    preferredCategories: ["сувениры"],
                    avoidCategories: [],
                    maxDistance: 3.0,
                    includeAudioGuides: false,
                    includeRestaurants: false,
                    includeShopping: true
                )
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func filterPOIs(pois: [POI], parameters: RouteParameters) -> [POI] {
        return pois.filter { poi in
            // Check if POI matches interests
            let matchesInterests = parameters.interests.isEmpty || 
                parameters.interests.contains { interest in
                    poi.categories.contains(interest) || poi.tags?.contains(interest) == true
                }
            
            // Check if POI is in preferred categories
            let matchesPreferred = parameters.preferredCategories.isEmpty ||
                parameters.preferredCategories.contains { category in
                    poi.categories.contains(category)
                }
            
            // Check if POI is not in avoided categories
            let notAvoided = parameters.avoidCategories.isEmpty ||
                !parameters.avoidCategories.contains { category in
                    poi.categories.contains(category)
                }
            
            // Check if POI has audio guides (if required)
            let hasAudio = !parameters.includeAudioGuides || !poi.audio.isEmpty
            
            return matchesInterests && matchesPreferred && notAvoided && hasAudio
        }
    }
    
    private func calculateOptimalRoute(pois: [POI], parameters: RouteParameters) -> [RouteStop] {
        guard !pois.isEmpty else { return [] }
        
        var remainingPOIs = pois
        var selectedStops: [RouteStop] = []
        var currentTime: TimeInterval = 0
        
        // Start with the first POI (or nearest to start location)
        if let startLocation = parameters.startLocation {
            // Find nearest POI to start location
            let nearestPOI = findNearestPOI(to: startLocation, in: remainingPOIs)
            if let nearest = nearestPOI {
                selectedStops.append(RouteStop(poiId: nearest.id, note: "Старт маршрута", dwellMin: 15))
                remainingPOIs.removeAll { $0.id == nearest.id }
                currentTime += 15
            }
        }
        
        // Add POIs until time limit is reached
        while !remainingPOIs.isEmpty && currentTime < parameters.maxDuration {
            let nextPOI = selectNextPOI(from: remainingPOIs, currentStops: selectedStops, parameters: parameters)
            
            guard let poi = nextPOI else { break }
            
            let dwellTime = calculateDwellTime(for: poi, parameters: parameters)
            let travelTime = calculateTravelTime(from: selectedStops.last, to: poi)
            
            if currentTime + dwellTime + travelTime <= parameters.maxDuration {
                selectedStops.append(RouteStop(poiId: poi.id, note: nil, dwellMin: Int(dwellTime)))
                remainingPOIs.removeAll { $0.id == poi.id }
                currentTime += dwellTime + travelTime
            } else {
                break
            }
        }
        
        return selectedStops
    }
    
    private func findNearestPOI(to location: CLLocationCoordinate2D, in pois: [POI]) -> POI? {
        return pois.min { poi1, poi2 in
            let distance1 = calculateDistance(from: location, to: poi1.coordinates)
            let distance2 = calculateDistance(from: location, to: poi2.coordinates)
            return distance1 < distance2
        }
    }
    
    private func selectNextPOI(from pois: [POI], currentStops: [RouteStop], parameters: RouteParameters) -> POI? {
        // Simple selection: prioritize by rating and category preference
        return pois.max { poi1, poi2 in
            let score1 = calculatePOIScore(poi: poi1, parameters: parameters)
            let score2 = calculatePOIScore(poi: poi2, parameters: parameters)
            return score1 < score2
        }
    }
    
    private func calculatePOIScore(poi: POI, parameters: RouteParameters) -> Double {
        var score = poi.rating
        
        // Bonus for preferred categories
        for category in parameters.preferredCategories {
            if poi.categories.contains(category) {
                score += 0.5
            }
        }
        
        // Bonus for having audio guides
        if !poi.audio.isEmpty {
            score += 0.3
        }
        
        return score
    }
    
    private func calculateDwellTime(for poi: POI, parameters: RouteParameters) -> TimeInterval {
        // Base dwell time based on categories
        var baseTime: TimeInterval = 20 // 20 minutes default
        
        if poi.categories.contains("музеи") {
            baseTime = 45
        } else if poi.categories.contains("архитектура") {
            baseTime = 30
        } else if poi.categories.contains("еда") {
            baseTime = 60
        } else if poi.categories.contains("сувениры") {
            baseTime = 15
        }
        
        // Adjust based on parameters
        if parameters.includeAudioGuides && !poi.audio.isEmpty {
            baseTime += 10 // Extra time for audio guide
        }
        
        return baseTime
    }
    
    private func calculateTravelTime(from lastStop: RouteStop?, to poi: POI) -> TimeInterval {
        // Simple calculation: assume 5 minutes per kilometer
        guard let lastStop = lastStop else { return 0 }
        
        // This would need actual POI data to calculate distance
        // For now, return a fixed time
        return 10 // 10 minutes between stops
    }
    
    private func generatePolyline(from stops: [RouteStop], startLocation: CLLocationCoordinate2D?) -> [Coordinates] {
        var coordinates: [Coordinates] = []
        
        // Add start location if provided
        if let start = startLocation {
            coordinates.append(Coordinates(lat: start.latitude, lng: start.longitude))
        }
        
        // Add coordinates for each stop
        for stop in stops {
            // This would need to fetch actual POI coordinates
            // For now, use placeholder coordinates
            coordinates.append(Coordinates(lat: 54.1834, lng: 45.1749))
        }
        
        return coordinates
    }
    
    private func calculateRouteMetrics(stops: [RouteStop], polyline: [Coordinates]) -> (duration: TimeInterval, distance: Double) {
        let totalDwellTime = stops.reduce(0) { $0 + TimeInterval($1.dwellMin ?? 0) }
        let travelTime = TimeInterval(stops.count - 1) * 10 // 10 minutes between stops
        let totalDuration = totalDwellTime + travelTime
        
        // Calculate distance from polyline
        let totalDistance = calculatePolylineDistance(polyline: polyline)
        
        return (totalDuration, totalDistance)
    }
    
    private func calculatePolylineDistance(polyline: [Coordinates]) -> Double {
        guard polyline.count > 1 else { return 0 }
        
        var totalDistance: Double = 0
        
        for i in 0..<(polyline.count - 1) {
            let coord1 = polyline[i]
            let coord2 = polyline[i + 1]
            
            let location1 = CLLocation(latitude: coord1.lat, longitude: coord1.lng)
            let location2 = CLLocation(latitude: coord2.lat, longitude: coord2.lng)
            
            totalDistance += location1.distance(from: location2) / 1000 // Convert to kilometers
        }
        
        return totalDistance
    }
    
    private func calculateDistance(from coord1: CLLocationCoordinate2D, to coord2: Coordinates) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.lat, longitude: coord2.lng)
        return location1.distance(from: location2)
    }
    
    private func createGeneratedRoute(stops: [RouteStop], polyline: [Coordinates], metrics: (duration: TimeInterval, distance: Double), parameters: RouteParameters) -> GeneratedRoute {
        let id = "custom-\(UUID().uuidString)"
        let title = generateRouteTitle(parameters: parameters, duration: metrics.duration)
        let description = generateRouteDescription(parameters: parameters, stops: stops)
        let difficulty = calculateDifficulty(duration: metrics.duration, distance: metrics.distance)
        let audioGuides = stops.compactMap { stop in
            // This would need to fetch actual POI data
            return "audio/poi/guide.m4a"
        }
        
        return GeneratedRoute(
            id: id,
            title: title,
            description: description,
            stops: stops,
            polyline: polyline,
            totalDuration: metrics.duration,
            totalDistance: metrics.distance,
            interests: parameters.interests,
            tags: generateTags(parameters: parameters),
            estimatedCost: calculateEstimatedCost(stops: stops),
            difficulty: difficulty,
            audioGuides: audioGuides
        )
    }
    
    private func generateRouteTitle(parameters: RouteParameters, duration: TimeInterval) -> String {
        let hours = Int(duration) / 60
        let interests = parameters.interests.joined(separator: ", ")
        return "Маршрут \(hours)ч: \(interests)"
    }
    
    private func generateRouteDescription(parameters: RouteParameters, stops: [RouteStop]) -> String {
        return "Персонализированный маршрут по \(stops.count) точкам интереса. Включает \(parameters.interests.joined(separator: ", "))."
    }
    
    private func calculateDifficulty(duration: TimeInterval, distance: Double) -> RouteDifficulty {
        let totalHours = duration / 60
        
        if totalHours <= 2 && distance <= 3 {
            return .easy
        } else if totalHours <= 4 && distance <= 6 {
            return .medium
        } else {
            return .hard
        }
    }
    
    private func generateTags(parameters: RouteParameters) -> [String] {
        var tags = ["персонализированный"]
        
        if parameters.includeAudioGuides {
            tags.append("аудиогид")
        }
        if parameters.includeRestaurants {
            tags.append("еда")
        }
        if parameters.includeShopping {
            tags.append("шоппинг")
        }
        
        return tags
    }
    
    private func calculateEstimatedCost(stops: [RouteStop]) -> Double? {
        // This would need actual POI data to calculate costs
        // For now, return a placeholder
        return Double(stops.count) * 200 // 200 rubles per stop
    }
    
    @MainActor
    private func updateProgress(_ progress: Double) {
        generationProgress = progress
    }
}