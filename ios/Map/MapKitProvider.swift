import SwiftUI
import MapKit

final class MapKitProvider: NSObject, ObservableObject, MapProvider, MKMapViewDelegate {
    private let mapView = MKMapView(frame: .zero)

    override init() {
        super.init()
        mapView.delegate = self
        mapView.pointOfInterestFilter = .excludingAll
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "pin")
        mapView.showsCompass = true
    }

    func setAnnotations(_ items: [MapPOIAnnotation]) {
        let existing = mapView.annotations
        mapView.removeAnnotations(existing)
        let pins = items.map { item -> MKPointAnnotation in
            let a = MKPointAnnotation()
            a.title = item.title
            a.coordinate = item.coordinate
            return a
        }
        mapView.addAnnotations(pins)
    }

    func setUserLocationEnabled(_ enabled: Bool) {
        mapView.showsUserLocation = enabled
    }

    func setRegion(center: CLLocationCoordinate2D, spanDegrees: Double) {
        let span = MKCoordinateSpan(latitudeDelta: spanDegrees, longitudeDelta: spanDegrees)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
    }

    // MARK: - Representable
    func representable() -> some View {
        MapContainer(mapView: mapView)
    }

    // MARK: - MKMapViewDelegate (customization point)
}

private struct MapContainer: UIViewRepresentable {
    let mapView: MKMapView
    func makeUIView(context: Context) -> MKMapView { mapView }
    func updateUIView(_ uiView: MKMapView, context: Context) {}
}