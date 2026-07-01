import MapKit
import CoreLocation

// Dubai airport terminal coordinates [VERIFY]
private let airportPickupZones: [(name: String, coordinate: CLLocationCoordinate2D, radiusKm: Double)] = [
    ("DXB T1", CLLocationCoordinate2D(latitude: 25.2532, longitude: 55.3657), 0.6),
    ("DXB T2", CLLocationCoordinate2D(latitude: 25.2495, longitude: 55.3627), 0.6),
    ("DXB T3", CLLocationCoordinate2D(latitude: 25.2520, longitude: 55.3644), 0.8),
    ("DWC",    CLLocationCoordinate2D(latitude: 24.8966, longitude: 55.1614), 1.2),
    ("AUH",    CLLocationCoordinate2D(latitude: 24.4330, longitude: 54.6511), 1.2),
    ("SHJ",    CLLocationCoordinate2D(latitude: 25.3286, longitude: 55.5174), 1.0),
]

struct RoutingService {

    static func computeRoute(from pickup: CLLocation, to dropoff: CLLocation) async throws -> RouteInfo {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: pickup.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: dropoff.coordinate))
        request.transportType = .automobile
        request.departureDate = Date()

        let response = try await MKDirections(request: request).calculate()
        guard let route = response.routes.first else {
            throw RoutingError.noRouteFound
        }

        let distanceKm = route.distance / 1000.0
        let durationMin = route.expectedTravelTime / 60.0
        let isAirport = isAirportPickup(pickup)

        // Salik estimate: based on distance band rather than geometric detection.
        // Geometric detection with coordinate matching is unreliable without exact
        // gantry GPS data. Distance bands match observed real-world toll patterns
        // for Dubai road trips. [CALIBRATE as real data is collected]
        let salikEst = estimateSalikGates(distanceKm: distanceKm)

        return RouteInfo(
            distanceKm: distanceKm,
            durationMin: durationMin,
            isAirportPickup: isAirport,
            salikGatesEstimate: salikEst
        )
    }

    // MARK: - Salik estimation by distance band
    // Dubai toll pattern: most short city trips (< 8 km) avoid tollways entirely.
    // Medium/long trips on SZR, Al Khail, or E311 typically hit 1–4 gates.
    private static func estimateSalikGates(distanceKm: Double) -> Int {
        switch distanceKm {
        case ..<8:   return 0   // mostly local streets
        case 8..<15: return 1   // one highway segment
        case 15..<25: return 2  // cross-city on SZR / Al Khail
        case 25..<35: return 3  // long cross-city
        default:     return 4   // far outlying areas (Jebel Ali, DWC, etc.)
        }
    }

    private static func isAirportPickup(_ location: CLLocation) -> Bool {
        airportPickupZones.contains { zone in
            let gate = CLLocation(latitude: zone.coordinate.latitude,
                                  longitude: zone.coordinate.longitude)
            return location.distance(from: gate) < zone.radiusKm * 1000
        }
    }

    enum RoutingError: LocalizedError {
        case noRouteFound
        var errorDescription: String? { "No driving route found between those locations." }
    }
}
