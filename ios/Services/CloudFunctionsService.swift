import Foundation
import FirebaseFunctions
import FirebaseAuth

class CloudFunctionsService: ObservableObject {
    static let shared = CloudFunctionsService()
    
    private let functions = Functions.functions()
    
    private init() {}
    
    // MARK: - Route Generation
    
    func generateRoute(
        interests: [String]? = nil,
        duration: Int,
        startLocation: Coordinates? = nil,
        maxDistance: Double = 10.0,
        includeClosedPOIs: Bool = false
    ) async throws -> Route {
        
        let data: [String: Any] = [
            "interests": interests ?? [],
            "duration": duration,
            "maxDistance": maxDistance,
            "includeClosedPOIs": includeClosedPOIs
        ]
        
        if let startLocation = startLocation {
            data["startLocation"] = [
                "lat": startLocation.lat,
                "lng": startLocation.lng
            ]
        }
        
        let result = try await functions.httpsCallable("generateRoute").call(data)
        
        guard let response = result.data as? [String: Any],
              let success = response["success"] as? Bool,
              success == true,
              let routeData = response["route"] as? [String: Any] else {
            throw CloudFunctionsError.invalidResponse
        }
        
        return try parseRouteFromData(routeData)
    }
    
    // MARK: - Spam Quota Checking
    
    func checkSpamQuota(contentType: ContentType, poiId: String) async throws -> SpamQuotaResult {
        let data: [String: Any] = [
            "contentType": contentType.rawValue,
            "poiId": poiId
        ]
        
        let result = try await functions.httpsCallable("checkSpamQuota").call(data)
        
        guard let response = result.data as? [String: Any],
              let success = response["success"] as? Bool,
              success == true,
              let remainingQuota = response["remainingQuota"] as? Int else {
            throw CloudFunctionsError.invalidResponse
        }
        
        return SpamQuotaResult(remainingQuota: remainingQuota)
    }
    
    // MARK: - Content Import
    
    func importOSMData(bounds: MapBounds, categories: [String]) async throws -> ImportResult {
        let data: [String: Any] = [
            "bounds": [
                "north": bounds.north,
                "south": bounds.south,
                "east": bounds.east,
                "west": bounds.west
            ],
            "categories": categories
        ]
        
        let result = try await functions.httpsCallable("importOSMData").call(data)
        
        guard let response = result.data as? [String: Any],
              let success = response["success"] as? Bool,
              success == true,
              let importedCount = response["importedCount"] as? Int,
              let savedCount = response["savedCount"] as? Int else {
            throw CloudFunctionsError.invalidResponse
        }
        
        return ImportResult(importedCount: importedCount, savedCount: savedCount)
    }
    
    func importWikidata(poiIds: [String]) async throws -> ImportResult {
        let data: [String: Any] = [
            "poiIds": poiIds
        ]
        
        let result = try await functions.httpsCallable("importWikidata").call(data)
        
        guard let response = result.data as? [String: Any],
              let success = response["success"] as? Bool,
              success == true,
              let updatedCount = response["updatedCount"] as? Int else {
            throw CloudFunctionsError.invalidResponse
        }
        
        return ImportResult(importedCount: 0, savedCount: updatedCount)
    }
    
    // MARK: - Helper Functions
    
    private func parseRouteFromData(_ data: [String: Any]) throws -> Route {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let durationMinutes = data["durationMinutes"] as? Int,
              let stopsData = data["stops"] as? [[String: Any]],
              let polylineData = data["polyline"] as? [[String: Any]],
              let tags = data["tags"] as? [String] else {
            throw CloudFunctionsError.invalidResponse
        }
        
        let distanceKm = data["distanceKm"] as? Double
        let description = data["description"] as? String
        
        // Parse stops
        let stops = try stopsData.map { stopData in
            guard let poiId = stopData["poiId"] as? String else {
                throw CloudFunctionsError.invalidResponse
            }
            let note = stopData["note"] as? String
            let dwellMin = stopData["dwellMin"] as? Int
            
            return RouteStop(poiId: poiId, note: note, dwellMin: dwellMin)
        }
        
        // Parse polyline
        let polyline = try polylineData.map { coordData in
            guard let lat = coordData["lat"] as? Double,
                  let lng = coordData["lng"] as? Double else {
                throw CloudFunctionsError.invalidResponse
            }
            return Coordinates(lat: lat, lng: lng)
        }
        
        return Route(
            id: id,
            title: title,
            durationMinutes: durationMinutes,
            distanceKm: distanceKm,
            interests: nil,
            stops: stops,
            polyline: polyline,
            tags: tags,
            meta: nil,
            description: description
        )
    }
}

// MARK: - Supporting Types

enum ContentType: String {
    case review = "review"
    case question = "question"
}

struct SpamQuotaResult {
    let remainingQuota: Int
}

struct ImportResult {
    let importedCount: Int
    let savedCount: Int
}

struct MapBounds {
    let north: Double
    let south: Double
    let east: Double
    let west: Double
}

enum CloudFunctionsError: LocalizedError {
    case invalidResponse
    case networkError
    case authenticationError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Неверный ответ от сервера"
        case .networkError:
            return "Ошибка сети"
        case .authenticationError:
            return "Ошибка аутентификации"
        }
    }
}