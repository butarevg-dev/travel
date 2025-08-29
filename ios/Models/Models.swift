import Foundation

struct Coordinates: Codable { let lat: Double; let lng: Double }
struct ContactInfo: Codable { let site: String?; let phone: String? }
struct ImageInfo: Codable { let src: String; let license: String?; let author: String? }
struct AudioInfo: Codable { let src: String; let durationSec: Int?; let voice: String? }
struct RatingInfo: Codable { let avg: Double; let count: Int }

struct POI: Codable, Identifiable {
    let id: String
    let title: String
    let categories: [String]
    let coordinates: Coordinates
    let address: String?
    let openingHours: String?
    let ticket: String?
    let contacts: ContactInfo?
    let short: String
    let description: String
    let images: [ImageInfo]
    let audio: [String] // Changed to array of strings to match usage
    let rating: Double // Changed to Double to match usage
    let tags: [String]?
    let meta: [String:String]?
}

struct RouteStop: Codable { let poiId: String; let note: String?; let dwellMin: Int? }

struct Route: Codable, Identifiable { // Renamed from RoutePlan to Route
    let id: String
    let title: String
    let durationMinutes: Int
    let distanceKm: Double?
    let interests: [String]?
    let stops: [RouteStop]
    let polyline: [Coordinates] // Changed to array of Coordinates to match usage
    let tags: [String]?
    let meta: [String:String]?
    let description: String? // Added to match usage
}

struct Review: Codable, Identifiable {
    let id: String
    let poiId: String
    let userId: String
    let rating: Int
    let text: String?
    let createdAt: Date
    var reported: Bool?
}

struct Question: Codable, Identifiable {
    let id: String
    let poiId: String
    let userId: String
    let text: String
    let createdAt: Date
    var answeredBy: String?
    var answerText: String?
    var status: String
}

struct Badge: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    // simplified rule model
    let ruleType: String
    let ruleParams: [String:String]?
}

struct Quest: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let tasks: [String] // simplified
    let rewardBadgeId: String?
}

struct UserProfile: Codable, Identifiable {
    let id: String
    let email: String?
    let displayName: String?
    let providers: [String]
    let favorites: [String]
    let badges: [String]
    let routeHistory: [String]
    let settings: [String:String]
    let premiumUntil: Date?
}