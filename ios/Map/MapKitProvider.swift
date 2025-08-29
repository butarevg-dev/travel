import SwiftUI
import MapKit

final class MapKitProvider: NSObject, ObservableObject, MapProvider, MKMapViewDelegate {
    private let mapView = MKMapView(frame: .zero)

    override init() {
        super.init()
        mapView.delegate = self
        mapView.pointOfInterestFilter = .excludingAll
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "pin")
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
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

    // MARK: - Overlay rendering (routes)
    func setPolyline(coordinates: [CLLocationCoordinate2D]) {
        let overlays = mapView.overlays
        mapView.removeOverlays(overlays)
        guard coordinates.count >= 2 else { return }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
        mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 80, left: 20, bottom: 160, right: 20), animated: true)
    }

    // MARK: - Representable
    func representable() -> some View {
        MapContainer(mapView: mapView, delegate: self)
    }

    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: "pin", for: annotation) as? MKMarkerAnnotationView
        view?.clusteringIdentifier = "poi"
        view?.glyphImage = UIImage(systemName: "mappin")
        view?.markerTintColor = UIColor.systemRed
        return view
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let r = MKPolylineRenderer(polyline: polyline)
            r.strokeColor = UIColor.systemBlue
            r.lineWidth = 4
            return r
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}

private struct MapContainer: UIViewRepresentable {
    let mapView: MKMapView
    let delegate: MKMapViewDelegate
    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = delegate
        return mapView
    }
    func updateUIView(_ uiView: MKMapView, context: Context) {}
}