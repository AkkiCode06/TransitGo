import Foundation
import CoreLocation

// MARK: - Provider

enum Provider: String, Codable, CaseIterable {
    case walking    = "walking"
    case hala       = "hala"
    case careem     = "careem"
    case zed        = "zed"
    case uber       = "uber"
    case yango      = "yango"
    case rtaMetro   = "rta_metro"
    case rtaBus     = "rta_bus"
    case rtaTaxi    = "rta_taxi"

    var displayName: String {
        switch self {
        case .walking:  return "Walk"
        case .hala:     return "Hala"
        case .careem:   return "Careem"
        case .zed:      return "Zed"
        case .uber:     return "Uber"
        case .yango:    return "Yango"
        case .rtaMetro: return "Metro"
        case .rtaBus:   return "RTA Bus"
        case .rtaTaxi:  return "RTA Taxi"
        }
    }

    var iconName: String {
        switch self {
        case .walking:  return "figure.walk"
        case .hala:     return "car.fill"
        case .careem:   return "car.fill"
        case .zed:      return "car.fill"
        case .uber:     return "car.fill"
        case .yango:    return "car.fill"
        case .rtaMetro: return "tram.fill"
        case .rtaBus:   return "bus.fill"
        case .rtaTaxi:  return "car.fill"
        }
    }

    var category: TransportCategory {
        switch self {
        case .walking:              return .walking
        case .rtaMetro, .rtaBus:    return .transit
        case .hala, .zed, .rtaTaxi: return .taxi
        case .uber, .careem, .yango: return .app
        }
    }
}

enum TransportCategory {
    case walking, transit, taxi, app
    var label: String {
        switch self {
        case .walking: return "Walk"
        case .transit: return "Public Transport"
        case .taxi:    return "E-Hail Taxi"
        case .app:     return "App Booking"
        }
    }
}

// MARK: - Bucket

enum ProviderBucket: String, Codable {
    case priced   // metered/zone — computed confidently
    case handoff  // dynamic — send user to provider app
}

// MARK: - QuoteOption

struct QuoteOption: Identifiable, Codable {
    let id: UUID
    let provider: Provider
    let bucket: ProviderBucket
    let fareMin: Double?
    let fareMax: Double?
    let currency: String
    let etaMinutes: Int?      // pickup wait
    let travelMinutes: Int?   // journey duration
    let disclaimer: String?
    let deepLink: String?
    let webFallbackURL: String?
    let appStoreURL: String?

    // Total door-to-door time (used for sorting)
    var totalMinutes: Int { (etaMinutes ?? 0) + (travelMinutes ?? 0) }

    var fareDisplay: String {
        guard let min = fareMin else { return "" }
        if let max = fareMax, max > min {
            return String(format: "AED %.0f–%.0f", min, max)
        }
        if min == 0 { return "Free" }
        return String(format: "AED %.0f", min)
    }
}

// MARK: - Trip request / response (backend)

struct TripRequest: Codable {
    let pickupLat, pickupLng: Double
    let dropoffLat, dropoffLng: Double
    let dropoffName: String
    let distanceKm, durationMin: Double
    let departureTime: String
    let isAirportPickup: Bool
    let salikGatesEstimate: Int
}

struct TripResponse: Codable {
    let options: [QuoteOption]
    let computedAt: String
}

// MARK: - Route info

struct RouteInfo {
    let distanceKm: Double
    let durationMin: Double
    let isAirportPickup: Bool
    let salikGatesEstimate: Int
}

// MARK: - Journey guidance

struct JourneyStep {
    let name: String
    let coordinate: CLLocationCoordinate2D
    let arrivalMin: Int  // minutes from journey start
}

struct GuidanceState {
    let option: QuoteOption
    var steps: [JourneyStep] = []
    var currentStepIndex: Int = 0
    var progressFraction: Double = 0   // 0–1

    var nextStep: JourneyStep? {
        guard currentStepIndex + 1 < steps.count else { return nil }
        return steps[currentStepIndex + 1]
    }
    var alightStep: JourneyStep? { steps.last }
    var isComplete: Bool { currentStepIndex >= steps.count - 1 }
}
