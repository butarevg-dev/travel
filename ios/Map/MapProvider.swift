import Foundation
import CoreLocation

public struct MapPOIAnnotation: Identifiable {
    public let id: String
    public let title: String
    public let coordinate: CLLocationCoordinate2D
    public let category: String
}

public protocol MapProvider: AnyObject {
    func setAnnotations(_ items: [MapPOIAnnotation])
    func setUserLocationEnabled(_ enabled: Bool)
    func setRegion(center: CLLocationCoordinate2D, spanDegrees: Double)
}