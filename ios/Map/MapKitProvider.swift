import SwiftUI
import MapKit

struct MapPOIAnnotation: Identifiable {
    let id: String
    let title: String
    let coordinate: CLLocationCoordinate2D
    let category: String
}

struct MapRoutePolyline: Identifiable {
    let id: String
    let title: String
    let coordinates: [CLLocationCoordinate2D]
    let color: UIColor
}

class MapKitProvider: NSObject, ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 54.1834, longitude: 45.1749),
        span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
    )
    
    private var annotations: [MapPOIAnnotation] = []
    private var polylines: [MapRoutePolyline] = []
    private var userLocationEnabled = false
    
    func representable() -> MapKitView {
        MapKitView(
            region: $region,
            annotations: annotations,
            polylines: polylines,
            userLocationEnabled: userLocationEnabled
        )
    }
    
    func setAnnotations(_ annotations: [MapPOIAnnotation]) {
        self.annotations = annotations
    }
    
    func setPolylines(_ polylines: [MapRoutePolyline]) {
        self.polylines = polylines
    }
    
    func setRegion(center: CLLocationCoordinate2D, spanDegrees: Double) {
        region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: spanDegrees, longitudeDelta: spanDegrees)
        )
    }
    
    func setUserLocationEnabled(_ enabled: Bool) {
        userLocationEnabled = enabled
    }
}

struct MapKitView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let annotations: [MapPOIAnnotation]
    let polylines: [MapRoutePolyline]
    let userLocationEnabled: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = userLocationEnabled
        mapView.showsCompass = true
        mapView.showsScale = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        
        // Update annotations
        mapView.removeAnnotations(mapView.annotations)
        let mkAnnotations = annotations.map { annotation in
            let mkAnnotation = MKPointAnnotation()
            mkAnnotation.coordinate = annotation.coordinate
            mkAnnotation.title = annotation.title
            return mkAnnotation
        }
        mapView.addAnnotations(mkAnnotations)
        
        // Update polylines
        mapView.removeOverlays(mapView.overlays)
        let mkPolylines = polylines.map { polyline in
            let mkPolyline = MKPolyline(coordinates: polyline.coordinates, count: polyline.coordinates.count)
            mkPolyline.title = polyline.title
            return mkPolyline
        }
        mapView.addOverlays(mkPolylines)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapKitView
        
        init(_ parent: MapKitView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !annotation.isKind(of: MKUserLocation.self) else { return nil }
            
            let identifier = "POIAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                annotationView?.markerTintColor = .red
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .red
                renderer.lineWidth = 4
                renderer.alpha = 0.8
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}