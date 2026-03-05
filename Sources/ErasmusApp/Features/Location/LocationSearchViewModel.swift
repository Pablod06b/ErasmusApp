import Foundation
import Combine
import MapKit

class LocationSearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchQuery = ""
    @Published var completions: [MKLocalSearchCompletion] = []
    
    private let completer: MKLocalSearchCompleter
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        completer = MKLocalSearchCompleter()
        // Provide a default region so it prefers local results (e.g. Salamanca/Spain)
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.9688, longitude: -5.6638), // Salamanca
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        super.init()
        completer.delegate = self
        
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                if query.count > 2 {
                    self?.completer.queryFragment = query
                } else {
                    self?.completions = []
                }
            }
            .store(in: &cancellables)
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Filter out results that aren't specific physical locations (like generic web searches)
        self.completions = completer.results.filter { $0.title != "" }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Location search failed: \(error.localizedDescription)")
    }
    
    // Convert a completion to actual CLLocationCoordinate2D
    func getCoordinate(for completion: MKLocalSearchCompletion) async throws -> CLLocationCoordinate2D {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        guard let coordinate = response.mapItems.first?.placemark.coordinate else {
            throw NSError(domain: "LocationSearch", code: 404, userInfo: [NSLocalizedDescriptionKey: "Coordenadas no encontradas"])
        }
        
        return coordinate
    }
}
