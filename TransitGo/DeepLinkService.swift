import UIKit
import CoreLocation

/// Handles booking handoffs to provider apps.
/// Schemes must be whitelisted in Info.plist under LSApplicationQueriesSchemes.
struct DeepLinkService {

    static func open(option: QuoteOption, pickup: CLLocation, dropoff: CLLocation, dropoffName: String) {
        guard let urlString = buildURL(option: option, pickup: pickup, dropoff: dropoff, dropoffName: dropoffName),
              let url = URL(string: urlString)
        else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            openFallback(for: option)
        }
    }

    // MARK: - URL builders

    private static func buildURL(option: QuoteOption, pickup: CLLocation, dropoff: CLLocation, dropoffName: String) -> String? {
        let pLat = pickup.coordinate.latitude
        let pLng = pickup.coordinate.longitude
        let dLat = dropoff.coordinate.latitude
        let dLng = dropoff.coordinate.longitude
        let encodedName = dropoffName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? dropoffName

        switch option.provider {

        case .hala, .careem:
            // Careem deep link opens the app but does NOT prefill coords (verified).
            return "careem://"

        case .zed:
            // No documented scheme — send to App Store.
            return nil

        case .uber:
            // Documented public deep link with route prefill.
            // Brackets must be percent-encoded.
            return "uber://?action=setPickup"
                + "&pickup%5Blatitude%5D=\(pLat)"
                + "&pickup%5Blongitude%5D=\(pLng)"
                + "&pickup%5Bnickname%5D=Pickup"
                + "&dropoff%5Blatitude%5D=\(dLat)"
                + "&dropoff%5Blongitude%5D=\(dLng)"
                + "&dropoff%5Bnickname%5D=\(encodedName)"

        case .yango:
            // Yango Universal Links — adjust with real partner link from their widget generator.
            return "yango://?ll=\(dLat),\(dLng)&text=\(encodedName)"

        case .rtaMetro, .rtaBus, .rtaTaxi:
            return "https://maps.apple.com/?saddr=\(pLat),\(pLng)&daddr=\(dLat),\(dLng)&dirflg=r"

        case .walking:
            return "https://maps.apple.com/?saddr=\(pLat),\(pLng)&daddr=\(dLat),\(dLng)&dirflg=w"
        }
    }

    private static func openFallback(for option: QuoteOption) {
        let storeURL: String
        switch option.provider {
        case .hala, .careem:
            storeURL = "https://apps.apple.com/ae/app/careem/id592978487"
        case .zed:
            storeURL = "https://apps.apple.com/ae/app/zed-taxi/id1441056939"
        case .uber:
            storeURL = "https://apps.apple.com/ae/app/uber-request-a-ride/id368677368"
        case .yango:
            storeURL = "https://apps.apple.com/ae/app/yango-taxi/id1239899024"
        case .rtaMetro, .rtaBus, .rtaTaxi, .walking:
            storeURL = "https://apps.apple.com/ae/app/s-hail/id1111549338"
        }

        if let url = URL(string: storeURL) {
            UIApplication.shared.open(url)
        }
    }
}
