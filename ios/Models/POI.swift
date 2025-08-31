import Foundation
import CoreLocation

struct POI: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let address: String
    let category: String
    let imageUrl: String
    let audioUrl: String
    let latitude: Double
    let longitude: Double
    let rating: Double
    let distance: Double
    let popularity: Int
    let workingHours: String?
    let price: String?
    let phone: String?
    let website: String?
    let tags: [String]
    let isFavorite: Bool
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case address
        case category
        case imageUrl
        case latitude
        case longitude
        case rating
        case distance
        case popularity
        case workingHours
        case price
        case phone
        case website
        case tags
        case isFavorite
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        address = try container.decode(String.self, forKey: .address)
        category = try container.decode(String.self, forKey: .category)
        imageUrl = try container.decode(String.self, forKey: .imageUrl)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        rating = try container.decode(Double.self, forKey: .rating)
        distance = try container.decode(Double.self, forKey: .distance)
        popularity = try container.decode(Int.self, forKey: .popularity)
        workingHours = try container.decodeIfPresent(String.self, forKey: .workingHours)
        price = try container.decodeIfPresent(String.self, forKey: .price)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        tags = try container.decode([String].self, forKey: .tags)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
    }
    
    init(id: String, name: String, description: String, address: String, category: String, imageUrl: String, audioUrl: String = "", latitude: Double, longitude: Double, rating: Double, distance: Double, popularity: Int, workingHours: String? = nil, price: String? = nil, phone: String? = nil, website: String? = nil, tags: [String] = [], isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.address = address
        self.category = category
        self.imageUrl = imageUrl
        self.audioUrl = audioUrl
        self.latitude = latitude
        self.longitude = longitude
        self.rating = rating
        self.distance = distance
        self.popularity = popularity
        self.workingHours = workingHours
        self.price = price
        self.phone = phone
        self.website = website
        self.tags = tags
        self.isFavorite = isFavorite
    }
}

// MARK: - POI Categories
enum POICategory: String, CaseIterable {
    case museums = "Музеи"
    case temples = "Храмы"
    case parks = "Парки"
    case restaurants = "Рестораны"
    case cafes = "Кафе"
    case shops = "Магазины"
    case entertainment = "Развлечения"
    case architecture = "Архитектура"
    case history = "История"
    case culture = "Культура"
    
    var icon: String {
        switch self {
        case .museums: return "building.2"
        case .temples: return "building.columns"
        case .parks: return "leaf"
        case .restaurants: return "fork.knife"
        case .cafes: return "cup.and.saucer"
        case .shops: return "bag"
        case .entertainment: return "gamecontroller"
        case .architecture: return "building"
        case .history: return "book"
        case .culture: return "theatermasks"
        }
    }
    
    var color: String {
        switch self {
        case .museums: return "blue"
        case .temples: return "orange"
        case .parks: return "green"
        case .restaurants: return "red"
        case .cafes: return "brown"
        case .shops: return "purple"
        case .entertainment: return "pink"
        case .architecture: return "gray"
        case .history: return "yellow"
        case .culture: return "indigo"
        }
    }
}

// MARK: - POI Filter
struct POIFilter {
    var categories: Set<POICategory> = []
    var minRating: Double = 0.0
    var maxDistance: Double = Double.infinity
    var priceRange: PriceRange = .all
    var isOpenNow: Bool = false
    var tags: Set<String> = []
    
    enum PriceRange: String, CaseIterable {
        case all = "Все"
        case free = "Бесплатно"
        case low = "До 500₽"
        case medium = "500₽ - 1000₽"
        case high = "Более 1000₽"
    }
}

// MARK: - POI Search
struct POISearch {
    var query: String = ""
    var location: CLLocation?
    var radius: Double = 5000 // meters
    var filter: POIFilter = POIFilter()
    
    var isEmpty: Bool {
        query.isEmpty && location == nil && filter.categories.isEmpty
    }
}

// MARK: - POI Review
struct POIReview: Identifiable, Codable {
    let id: String
    let poiId: String
    let userId: String
    let userName: String
    let rating: Int
    let comment: String
    let date: Date
    let photos: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case poiId
        case userId
        case userName
        case rating
        case comment
        case date
        case photos
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        poiId = try container.decode(String.self, forKey: .poiId)
        userId = try container.decode(String.self, forKey: .userId)
        userName = try container.decode(String.self, forKey: .userName)
        rating = try container.decode(Int.self, forKey: .rating)
        comment = try container.decode(String.self, forKey: .comment)
        date = try container.decode(Date.self, forKey: .date)
        photos = try container.decode([String].self, forKey: .photos)
    }
    
    init(id: String, poiId: String, userId: String, userName: String, rating: Int, comment: String, date: Date, photos: [String] = []) {
        self.id = id
        self.poiId = poiId
        self.userId = userId
        self.userName = userName
        self.rating = rating
        self.comment = comment
        self.date = date
        self.photos = photos
    }
}

// MARK: - POI Statistics
struct POIStatistics {
    let totalPOIs: Int
    let visitedPOIs: Int
    let favoritePOIs: Int
    let averageRating: Double
    let totalReviews: Int
    let categories: [POICategory: Int]
    
    var visitPercentage: Double {
        guard totalPOIs > 0 else { return 0 }
        return Double(visitedPOIs) / Double(totalPOIs) * 100
    }
    
    var favoritePercentage: Double {
        guard totalPOIs > 0 else { return 0 }
        return Double(favoritePOIs) / Double(totalPOIs) * 100
    }
}