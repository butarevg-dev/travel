import Foundation
import CoreLocation

class RouteCalculator {
    static let shared = RouteCalculator()
    
    // Average walking speed in meters per second (4.5 km/h = 1.25 m/s)
    private let walkingSpeed: Double = 1.25
    
    // Average time spent at each POI in minutes
    private let averageTimePerPOI: Double = 15.0
    
    private init() {}
    
    /// Calculate walking time between two coordinates
    func calculateWalkingTime(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> TimeInterval {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        
        let distance = fromLocation.distance(from: toLocation)
        return distance / walkingSpeed
    }
    
    /// Calculate total route time including walking and POI visits
    func calculateTotalRouteTime(route: Route, pois: [POI]) -> RouteTimeInfo {
        var totalWalkingTime: TimeInterval = 0
        var totalDistance: Double = 0
        var poiVisitTime: TimeInterval = 0
        
        // Get POIs for this route
        let routePOIs = pois.filter { poi in
            route.stops.contains { $0.poiId == poi.id }
        }
        
        // Calculate walking time between consecutive POIs
        for i in 0..<routePOIs.count - 1 {
            let fromPOI = routePOIs[i]
            let toPOI = routePOIs[i + 1]
            
            let fromCoord = CLLocationCoordinate2D(latitude: fromPOI.coordinates.lat, longitude: fromPOI.coordinates.lng)
            let toCoord = CLLocationCoordinate2D(latitude: toPOI.coordinates.lat, longitude: toPOI.coordinates.lng)
            
            let walkingTime = calculateWalkingTime(from: fromCoord, to: toCoord)
            totalWalkingTime += walkingTime
            
            let fromLocation = CLLocation(latitude: fromPOI.coordinates.lat, longitude: fromPOI.coordinates.lng)
            let toLocation = CLLocation(latitude: toPOI.coordinates.lat, longitude: toPOI.coordinates.lng)
            totalDistance += fromLocation.distance(from: toLocation)
        }
        
        // Calculate POI visit time
        poiVisitTime = Double(routePOIs.count) * averageTimePerPOI * 60 // Convert to seconds
        
        let totalTime = totalWalkingTime + poiVisitTime
        
        return RouteTimeInfo(
            totalTime: totalTime,
            walkingTime: totalWalkingTime,
            poiVisitTime: poiVisitTime,
            totalDistance: totalDistance,
            poiCount: routePOIs.count
        )
    }
    
    /// Format time interval to human readable string
    func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)ч \(minutes)мин"
        } else {
            return "\(minutes)мин"
        }
    }
    
    /// Format distance to human readable string
    func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1f км", distance / 1000)
        } else {
            return String(format: "%.0f м", distance)
        }
    }
}

struct RouteTimeInfo {
    let totalTime: TimeInterval
    let walkingTime: TimeInterval
    let poiVisitTime: TimeInterval
    let totalDistance: Double
    let poiCount: Int
    
    var formattedTotalTime: String {
        RouteCalculator.shared.formatTime(totalTime)
    }
    
    var formattedWalkingTime: String {
        RouteCalculator.shared.formatTime(walkingTime)
    }
    
    var formattedDistance: String {
        RouteCalculator.shared.formatDistance(totalDistance)
    }
}