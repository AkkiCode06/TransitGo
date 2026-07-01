import Foundation
import CoreLocation

private let backendBaseURL = ""
// Set to your Railway URL once deployed: "https://transitgo-api.railway.app"

final class QuoteService {
    static let shared = QuoteService()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        session = URLSession(configuration: config)
    }

    func fetchQuotes(
        pickup: CLLocation,
        dropoff: CLLocation,
        dropoffName: String,
        routeInfo: RouteInfo,
        prefs: UserPreferences
    ) async throws -> [QuoteOption] {
        if !backendBaseURL.isEmpty, let url = URL(string: "\(backendBaseURL)/quote") {
            if let options = try? await fetchFromBackend(url: url, pickup: pickup, dropoff: dropoff,
                                                         dropoffName: dropoffName, routeInfo: routeInfo) {
                return options
            }
        }
        return LocalFareEngine.computeQuotes(route: routeInfo, prefs: prefs)
    }

    private func fetchFromBackend(url: URL, pickup: CLLocation, dropoff: CLLocation,
                                  dropoffName: String, routeInfo: RouteInfo) async throws -> [QuoteOption] {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = TripRequest(
            pickupLat: pickup.coordinate.latitude, pickupLng: pickup.coordinate.longitude,
            dropoffLat: dropoff.coordinate.latitude, dropoffLng: dropoff.coordinate.longitude,
            dropoffName: dropoffName, distanceKm: routeInfo.distanceKm,
            durationMin: routeInfo.durationMin,
            departureTime: ISO8601DateFormatter().string(from: Date()),
            isAirportPickup: routeInfo.isAirportPickup,
            salikGatesEstimate: routeInfo.salikGatesEstimate
        )
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(TripResponse.self, from: data).options
            .sorted { $0.totalMinutes < $1.totalMinutes }
    }
}
