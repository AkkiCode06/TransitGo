import Foundation
import CoreLocation
import Combine

@MainActor
final class TripViewModel: ObservableObject {

    // MARK: - State

    enum ViewState: Equatable {
        case idle
        case routing
        case loading
        case results
        case error(String)
    }

    @Published var state: ViewState = .idle
    @Published var dropoffQuery: String = ""
    @Published var pickupLabel: String = "Locating..."
    @Published var dropoffLabel: String = ""
    @Published var quotes: [QuoteOption] = []

    var pickupLocation: CLLocation?
    var dropoffLocation: CLLocation?
    var routeInfo: RouteInfo?

    let locationService: LocationService
    var prefs: UserPreferences = UserPreferences()
    private var cancelBag = Set<AnyCancellable>()

    init(locationService: LocationService) {
        self.locationService = locationService
        bindLocation()
    }

    // MARK: - Bind to location service

    private func bindLocation() {
        locationService.$currentLocation
            .compactMap { $0 }
            .first()
            .sink { [weak self] location in
                self?.pickupLocation = location
                Task { [weak self] in
                    guard let self else { return }
                    let label = try? await self.locationService.reverseGeocode(location)
                    self.pickupLabel = label ?? "Current Location"
                }
            }
            .store(in: &cancelBag)
    }

    // MARK: - Route to a pre-resolved location (from autocomplete tap)

    func routeTo(dropoff: CLLocation, name: String) {
        dropoffLocation = dropoff
        dropoffLabel = name
        dropoffQuery = name
        Task { await computeRouteAndFetch() }
    }

    // MARK: - Fallback: geocode from text (used when user submits the field directly)

    func searchAndRoute() {
        guard !dropoffQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        Task {
            do {
                state = .routing
                let dropoff = try await locationService.geocode(dropoffQuery)
                dropoffLocation = dropoff
                dropoffLabel = dropoffQuery
                await computeRouteAndFetch()
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - Shared route + fetch pipeline

    private func computeRouteAndFetch() async {
        guard let pickup = pickupLocation, let dropoff = dropoffLocation else {
            state = .error("Could not determine pickup location.")
            return
        }

        do {
            state = .routing
            let route = try await RoutingService.computeRoute(from: pickup, to: dropoff)
            routeInfo = route

            state = .loading
            quotes = try await QuoteService.shared.fetchQuotes(
                pickup: pickup,
                dropoff: dropoff,
                dropoffName: dropoffLabel,
                routeInfo: route,
                prefs: prefs
            )
            state = .results
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Handoff

    func openProvider(_ option: QuoteOption) {
        guard let pickup = pickupLocation, let dropoff = dropoffLocation else { return }
        DeepLinkService.open(option: option, pickup: pickup, dropoff: dropoff, dropoffName: dropoffLabel)
    }

    // MARK: - Refresh (e.g. after toggling Salik)

    func refreshQuotes() async {
        guard let pickup = pickupLocation, let dropoff = dropoffLocation,
              let route = routeInfo else { return }
        state = .loading
        do {
            quotes = try await QuoteService.shared.fetchQuotes(
                pickup: pickup, dropoff: dropoff,
                dropoffName: dropoffLabel, routeInfo: route, prefs: prefs
            )
            state = .results
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Reset

    func reset() {
        state = .idle
        dropoffQuery = ""
        dropoffLabel = ""
        dropoffLocation = nil
        routeInfo = nil
        quotes = []
    }

    var pricedOptions: [QuoteOption]  { quotes.filter { $0.bucket == .priced } }
    var handoffOptions: [QuoteOption] { quotes.filter { $0.bucket == .handoff } }
}
