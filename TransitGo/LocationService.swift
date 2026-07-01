import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: LocationError?

    private let manager = CLLocationManager()

    enum LocationError: LocalizedError {
        case denied
        case unavailable
        var errorDescription: String? {
            switch self {
            case .denied:      return "Location access denied. Enable it in Settings."
            case .unavailable: return "Location unavailable. Check device settings."
            }
        }
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    func geocode(_ address: String) async throws -> CLLocation {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(address)
        guard let location = placemarks.first?.location else {
            throw LocationError.unavailable
        }
        return location
    }

    func reverseGeocode(_ location: CLLocation) async throws -> String {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        guard let placemark = placemarks.first else { return "Current Location" }
        let parts = [placemark.name, placemark.thoroughfare, placemark.subLocality]
            .compactMap { $0 }
        return parts.first ?? "Current Location"
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.manager.startUpdatingLocation()
            case .denied, .restricted:
                error = .denied
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            currentLocation = location
            // One good fix is enough for pickup
            self.manager.stopUpdatingLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = .unavailable
        }
    }
}
