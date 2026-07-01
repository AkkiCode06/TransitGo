import MapKit
import Combine

@MainActor
final class LocationSearchService: NSObject, ObservableObject {
    @Published var suggestions: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        // Bias results toward UAE
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 25.2048, longitude: 55.2708),
            span: MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4)
        )
    }

    func update(query: String) {
        if query.isEmpty {
            suggestions = []
        } else {
            completer.queryFragment = query
        }
    }

    func clear() {
        suggestions = []
        completer.queryFragment = ""
    }

    /// Resolves a completion to a concrete CLLocation + display name.
    func resolve(_ completion: MKLocalSearchCompletion) async throws -> (CLLocation, String) {
        let request = MKLocalSearch.Request(completion: completion)
        let response = try await MKLocalSearch(request: request).start()
        guard let item = response.mapItems.first else {
            throw ResolutionError.noResult
        }
        let coord = item.placemark.coordinate
        let name = item.name ?? completion.title
        return (CLLocation(latitude: coord.latitude, longitude: coord.longitude), name)
    }

    enum ResolutionError: LocalizedError {
        case noResult
        var errorDescription: String? { "Location not found." }
    }
}

extension LocationSearchService: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in self.suggestions = Array(completer.results.prefix(6)) }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in self.suggestions = [] }
    }
}
