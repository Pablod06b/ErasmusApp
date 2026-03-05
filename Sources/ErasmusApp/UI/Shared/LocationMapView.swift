import SwiftUI
import MapKit

struct LocationMapView: View {
    let locationName: String
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.9688, longitude: -5.6638), // Salamanca default
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var markers: [LocationMarker] = []
    
    struct LocationMarker: Identifiable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: markers) { marker in
            MapMarker(coordinate: marker.coordinate, tint: .blue)
        }
        .onAppear {
            geocodeLocation(locationName)
        }
    }
    
    private func geocodeLocation(_ location: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { placemarks, error in
            if let coordinate = placemarks?.first?.location?.coordinate {
                DispatchQueue.main.async {
                    self.region = MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                    self.markers = [LocationMarker(name: location, coordinate: coordinate)]
                }
            }
        }
    }
}
