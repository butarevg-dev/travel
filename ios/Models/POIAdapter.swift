import Foundation

// MARK: - POI Adapter for Backward Compatibility
struct POIAdapter {
    
    // MARK: - Convert new POI to old format
    static func toLegacyPOI(_ newPOI: POI) -> LegacyPOI {
        return LegacyPOI(
            id: newPOI.id,
            title: newPOI.name,
            categories: [newPOI.category],
            coordinates: Coordinates(lat: newPOI.latitude, lng: newPOI.longitude),
            address: newPOI.address,
            openingHours: newPOI.workingHours,
            ticket: newPOI.price,
            contacts: ContactInfo(site: newPOI.website, phone: newPOI.phone),
            short: String(newPOI.description.prefix(100)),
            description: newPOI.description,
            images: [ImageInfo(src: newPOI.imageUrl, license: nil, author: nil)],
            audio: newPOI.audioUrl.isEmpty ? [] : [newPOI.audioUrl],
            rating: newPOI.rating,
            tags: newPOI.tags,
            meta: nil
        )
    }
    
    // MARK: - Convert old POI to new format
    static func toNewPOI(_ legacyPOI: LegacyPOI) -> POI {
        return POI(
            id: legacyPOI.id,
            name: legacyPOI.title,
            description: legacyPOI.description,
            address: legacyPOI.address ?? "",
            category: legacyPOI.categories.first ?? "other",
            imageUrl: legacyPOI.images.first?.src ?? "",
            audioUrl: legacyPOI.audio.first ?? "",
            latitude: legacyPOI.coordinates.lat,
            longitude: legacyPOI.coordinates.lng,
            rating: legacyPOI.rating,
            distance: 0,
            popularity: 0,
            workingHours: legacyPOI.openingHours,
            price: legacyPOI.ticket,
            phone: legacyPOI.contacts?.phone,
            website: legacyPOI.contacts?.site,
            tags: legacyPOI.tags ?? [],
            isFavorite: false
        )
    }
}

// MARK: - Legacy POI Model (from Models.swift)
struct LegacyPOI: Codable, Identifiable {
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
    let audio: [String]
    let rating: Double
    let tags: [String]?
    let meta: [String:String]?
}

// MARK: - Supporting Structures
struct Coordinates: Codable { 
    let lat: Double
    let lng: Double 
}

struct ContactInfo: Codable { 
    let site: String?
    let phone: String? 
}

struct ImageInfo: Codable { 
    let src: String
    let license: String?
    let author: String? 
}

// MARK: - POI Extension for Compatibility
extension POI {
    
    // MARK: - Legacy Properties (for backward compatibility)
    var title: String { name }
    var categories: [String] { [category] }
    var coordinates: Coordinates { 
        Coordinates(lat: latitude, lng: longitude) 
    }
    
    // MARK: - Legacy Methods
    func toLegacy() -> LegacyPOI {
        return POIAdapter.toLegacyPOI(self)
    }
    
    static func fromLegacy(_ legacy: LegacyPOI) -> POI {
        return POIAdapter.toNewPOI(legacy)
    }
}

// MARK: - Legacy POI Extension for Forward Compatibility
extension LegacyPOI {
    
    // MARK: - New Properties (for forward compatibility)
    var name: String { title }
    var category: String { categories.first ?? "other" }
    var latitude: Double { coordinates.lat }
    var longitude: Double { coordinates.lng }
    var imageUrl: String { images.first?.src ?? "" }
    var audioUrl: String { audio.first ?? "" }
    var workingHours: String? { openingHours }
    var price: String? { ticket }
    var phone: String? { contacts?.phone }
    var website: String? { contacts?.site }
    
    // MARK: - New Methods
    func toNew() -> POI {
        return POIAdapter.toNewPOI(self)
    }
    
    static func fromNew(_ new: POI) -> LegacyPOI {
        return POIAdapter.toLegacyPOI(new)
    }
}