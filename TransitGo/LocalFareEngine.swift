import Foundation

// MARK: - RTA Constants

private enum RTA {
    static let appBase:          Double = 12.00   // Hala/Zed meter starts here
    static let streetBaseDay:    Double = 5.00
    static let streetBaseNight:  Double = 5.50
    static let perKmLow:         Double = 2.09    // [VERIFY monthly fuel adjustment]
    static let perKmHigh:        Double = 2.26
    static let perMinWait:       Double = 0.50
    static let surgeCapApp:      Double = 1.30    // regulated max multiplier
    static let minFareApp:       Double = 13.00
    static let minFareStreet:    Double = 12.00
    static let airportSurcharge: Double = 20.00
    static let salikPerGate:     Double = 4.00
    static let waitFraction:     Double = 0.20    // ~20% of drive time = stop-and-go
    static let nightStart = 22;  static let nightEnd = 6
}

private enum Uber {
    static let base:    Double = 9.00
    static let perKm:   Double = 1.90
    static let perMin:  Double = 0.30
    static let booking: Double = 1.50
    static let min:     Double = 15.00
    static let airport: Double = 20.00
    static let surgeLow:  Double = 1.0
    static let surgeHigh: Double = 1.5
}

private enum Nol {
    static let zone1:     Double = 3.00
    static let zone2:     Double = 5.00
    static let zone3plus: Double = 7.50
    static let busFlat:   Double = 2.00
    static let metroKmph: Double = 40.0
}

private enum Walk {
    static let speedKmh:  Double = 5.0
    static let maxMinutes: Int   = 35   // only show walk if under 35 min
}

// MARK: - Engine

enum LocalFareEngine {

    static func computeQuotes(
        route: RouteInfo,
        departureDate: Date = Date(),
        prefs: UserPreferences
    ) -> [QuoteOption] {
        let night    = isNight(departureDate)
        let travelMin = Int(route.durationMin)
        let waitMin   = route.durationMin * RTA.waitFraction
        let salik     = prefs.includeSalik ? route.salikGatesEstimate : 0
        let salikCost = RTA.salikPerGate * Double(salik)

        // App-hail fare range (Hala / Zed)
        var appLow  = RTA.appBase + RTA.perKmLow  * route.distanceKm + salikCost
        var appHigh = (RTA.appBase + RTA.perKmHigh * route.distanceKm
                       + RTA.perMinWait * waitMin + salikCost) * RTA.surgeCapApp
        if route.isAirportPickup { appLow += RTA.airportSurcharge; appHigh += RTA.airportSurcharge }
        appLow  = max(round(appLow),  RTA.minFareApp)
        appHigh = max(round(appHigh), RTA.minFareApp)

        if prefs.careemPlusActive {
            let d = 1 - UserPreferences.careemPlusDiscount
            appLow = (appLow * d * 100).rounded() / 100
            appHigh = (appHigh * d * 100).rounded() / 100
        }

        // Street taxi range
        let streetBase = night ? RTA.streetBaseNight : RTA.streetBaseDay
        var stLow  = streetBase + RTA.perKmLow  * route.distanceKm + salikCost
        var stHigh = streetBase + RTA.perKmHigh * route.distanceKm + RTA.perMinWait * waitMin + salikCost
        if route.isAirportPickup { stLow += RTA.airportSurcharge; stHigh += RTA.airportSurcharge }
        stLow  = max(round(stLow),  RTA.minFareStreet)
        stHigh = max(round(stHigh), RTA.minFareStreet)

        // Uber range
        var uBase = Uber.base + Uber.perKm * route.distanceKm
            + Uber.perMin * route.durationMin + Uber.booking + salikCost
        if route.isAirportPickup { uBase += Uber.airport }
        uBase = max(uBase, Uber.min)
        var uLow  = round(uBase * Uber.surgeLow)
        var uHigh = round(uBase * Uber.surgeHigh)
        if prefs.uberOneActive {
            let d = 1 - UserPreferences.uberOneDiscount
            uLow = (uLow * d).rounded(); uHigh = (uHigh * d).rounded()
        }

        let salikNote = salik > 0 ? "Incl. est. \(salik)× Salik @ AED 4 each." : nil

        var opts: [QuoteOption] = []

        // ── WALKING ────────────────────────────────────────────────────
        let walkMin = Int(route.distanceKm / Walk.speedKmh * 60 * 1.1) // ×1.1 road factor
        if walkMin <= Walk.maxMinutes {
            opts.append(QuoteOption(
                id: UUID(), provider: .walking, bucket: .priced,
                fareMin: 0, fareMax: 0, currency: "AED",
                etaMinutes: 0, travelMinutes: walkMin,
                disclaimer: "Estimated walking time. Actual route may vary.",
                deepLink: nil, webFallbackURL: nil, appStoreURL: nil
            ))
        }

        // ── PUBLIC TRANSPORT ───────────────────────────────────────────
        let nol      = nolFare(distanceKm: route.distanceKm)
        let metroMin = Int(route.distanceKm / Nol.metroKmph * 60) + 10

        opts.append(QuoteOption(
            id: UUID(), provider: .rtaMetro, bucket: .priced,
            fareMin: nol, fareMax: nol, currency: "AED",
            etaMinutes: 5, travelMinutes: metroMin,
            disclaimer: "Nol Silver card. \(metroMin) min est. includes walk to/from station. Not all destinations are Metro-accessible.",
            deepLink: nil, webFallbackURL: nil,
            appStoreURL: "https://apps.apple.com/ae/app/s-hail/id1111549338"
        ))

        opts.append(QuoteOption(
            id: UUID(), provider: .rtaBus, bucket: .priced,
            fareMin: Nol.busFlat, fareMax: Nol.busFlat, currency: "AED",
            etaMinutes: 8, travelMinutes: travelMin + 20,
            disclaimer: "Nol Silver card. Check S'hail app for route number and stop timings.",
            deepLink: nil, webFallbackURL: nil,
            appStoreURL: "https://apps.apple.com/ae/app/s-hail/id1111549338"
        ))

        // ── E-HAIL TAXI ────────────────────────────────────────────────
        opts.append(QuoteOption(
            id: UUID(), provider: .hala, bucket: .priced,
            fareMin: appLow, fareMax: appHigh, currency: "AED",
            etaMinutes: 4, travelMinutes: travelMin,
            disclaimer: ["AED 12 base · AED 2.09–2.26/km · AED 0.50/min traffic · 1.3× surge cap.", salikNote, prefs.careemPlusActive ? "Careem Plus ~10% applied." : nil].compactMap{$0}.joined(separator: " "),
            deepLink: "careem://", webFallbackURL: nil,
            appStoreURL: "https://apps.apple.com/ae/app/careem/id592978487"
        ))

        opts.append(QuoteOption(
            id: UUID(), provider: .zed, bucket: .priced,
            fareMin: appLow, fareMax: appHigh, currency: "AED",
            etaMinutes: 5, travelMinutes: travelMin,
            disclaimer: ["Same RTA meter as Hala.", salikNote].compactMap{$0}.joined(separator: " "),
            deepLink: nil, webFallbackURL: nil,
            appStoreURL: "https://apps.apple.com/ae/app/zed-taxi/id1441056939"
        ))

        opts.append(QuoteOption(
            id: UUID(), provider: .rtaTaxi, bucket: .priced,
            fareMin: stLow, fareMax: stHigh, currency: "AED",
            etaMinutes: 7, travelMinutes: travelMin,
            disclaimer: ["Street-hail: AED \(night ? "5.50" : "5.00") base.", salikNote].compactMap{$0}.joined(separator: " "),
            deepLink: nil, webFallbackURL: nil,
            appStoreURL: "https://apps.apple.com/ae/app/s-hail/id1111549338"
        ))

        // ── PREMIUM APP ────────────────────────────────────────────────
        opts.append(QuoteOption(
            id: UUID(), provider: .uber, bucket: .handoff,
            fareMin: uLow, fareMax: uHigh, currency: "AED",
            etaMinutes: 3, travelMinutes: travelMin,
            disclaimer: "Independent estimate — not from Uber's API. Actual price set by Uber; may vary with surge." + (prefs.uberOneActive ? " Uber One ~5% applied." : ""),
            deepLink: nil, webFallbackURL: "https://m.uber.com/looking",
            appStoreURL: "https://apps.apple.com/ae/app/uber-request-a-ride/id368677368"
        ))

        opts.append(QuoteOption(
            id: UUID(), provider: .careem, bucket: .handoff,
            fareMin: nil, fareMax: nil, currency: "AED",
            etaMinutes: nil, travelMinutes: travelMin,
            disclaimer: "Live Careem pricing — may include surge.",
            deepLink: "careem://", webFallbackURL: nil,
            appStoreURL: "https://apps.apple.com/ae/app/careem/id592978487"
        ))

        // Sort by total door-to-door time (fastest first)
        return opts.sorted { $0.totalMinutes < $1.totalMinutes }
    }

    // MARK: - Helpers

    private static func isNight(_ d: Date) -> Bool {
        let h = Calendar.current.component(.hour, from: d)
        return h >= RTA.nightStart || h < RTA.nightEnd
    }

    private static func nolFare(distanceKm: Double) -> Double {
        if distanceKm <= 12 { return Nol.zone1 }
        if distanceKm <= 28 { return Nol.zone2 }
        return Nol.zone3plus
    }
}
