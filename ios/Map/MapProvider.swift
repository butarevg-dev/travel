import Foundation
import CoreLocation

public protocol MapProvider: AnyObject {
    func setAnnotations(_ items: [MapPOIAnnotation])
    func setUserLocationEnabled(_ enabled: Bool)
    func setRegion(center: CLLocationCoordinate2D, spanDegrees: Double)
}