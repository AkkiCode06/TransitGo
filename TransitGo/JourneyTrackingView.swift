import SwiftUI
import Combine
import CoreLocation
import MapKit

// MARK: - Journey Tracking View
// Passive guidance tool — NOT turn-by-turn navigation.
// Tracks user location and shows where they are along the route,
// which stop is next, and when to alight.

struct JourneyTrackingView: View {
    let option: QuoteOption
    let pickup: CLLocation
    let dropoff: CLLocation
    let dropoffName: String
    @Binding var isPresented: Bool

    @StateObject private var tracker = JourneyTracker()

    var body: some View {
        ZStack(alignment: .bottom) {
            // Map
            TrackingMapView(
                userLocation: tracker.currentLocation?.coordinate,
                pickup: pickup.coordinate,
                dropoff: dropoff.coordinate,
                nearestStation: tracker.nearestStation
            )
            .ignoresSafeArea()

            // Bottom guidance panel
            guidancePanel
                .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            tracker.start(option: option, pickup: pickup, dropoff: dropoff)
        }
        .onDisappear { tracker.stop() }
    }

    // MARK: - Guidance panel

    private var guidancePanel: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            // Destination header
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("To \(dropoffName)")
                        .font(DS.bodyFont(18, weight: .bold))
                        .foregroundStyle(DS.textPrimary)
                    HStack(spacing: 6) {
                        Image(systemName: option.provider.iconName)
                            .font(.system(size: 11))
                        Text(option.provider.displayName)
                            .font(DS.monoFont(11))
                    }
                    .foregroundStyle(option.provider.brandColor)
                }
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DS.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(DS.surfaceRaised)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, DS.margin)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider().background(DS.border)

            // Main guidance content
            Group {
                switch option.provider {
                case .rtaMetro, .rtaBus:
                    transitGuidance
                case .walking:
                    walkingGuidance
                default:
                    taxiGuidance
                }
            }
            .padding(.horizontal, DS.margin)
            .padding(.vertical, 16)

            // Progress bar
            progressBar

            // ETA footer
            etaFooter

            Spacer().frame(height: 28)
        }
        .background(DS.bg)
        .clipShape(RoundedCorners(radius: 22, corners: [.topLeft, .topRight]))
        .frame(height: 320)
    }

    // MARK: - Transit guidance (Metro / Bus)

    private var transitGuidance: some View {
        VStack(spacing: 16) {
            if let station = tracker.nearestStation {
                // Current station
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(DS.orange).frame(width: 40, height: 40)
                        Image(systemName: "tram.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("You are near")
                            .font(DS.monoFont(10))
                            .foregroundStyle(DS.textTertiary)
                        Text(station.name)
                            .font(DS.bodyFont(16, weight: .semibold))
                            .foregroundStyle(DS.textPrimary)
                        Text(station.line.rawValue)
                            .font(DS.monoFont(10))
                            .foregroundStyle(DS.textSecondary)
                    }
                    Spacer()
                    if let dist = tracker.distanceToDropoffKm {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.1f km", dist))
                                .font(DS.bodyFont(15, weight: .bold))
                                .foregroundStyle(DS.orange)
                            Text("to go")
                                .font(DS.monoFont(9))
                                .foregroundStyle(DS.textTertiary)
                        }
                    }
                }

                // Alight notification
                if let alight = tracker.alightStation {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.orange)
                        Text("Alight at  ")
                            .font(DS.bodyFont(13))
                            .foregroundStyle(DS.textSecondary)
                        + Text(alight.name)
                            .font(DS.bodyFont(13, weight: .bold))
                            .foregroundStyle(DS.textPrimary)
                        Spacer()
                    }
                    .padding(10)
                    .background(DS.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.orange.opacity(0.3), lineWidth: 1))
                }

            } else {
                // No station detected — generic guidance
                HStack(spacing: 12) {
                    ProgressView().tint(DS.orange)
                    Text("Detecting your location…")
                        .font(DS.bodyFont(14))
                        .foregroundStyle(DS.textSecondary)
                }
            }
        }
    }

    // MARK: - Walking guidance

    private var walkingGuidance: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(DS.orange).frame(width: 40, height: 40)
                Image(systemName: "figure.walk")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Walking to destination")
                    .font(DS.bodyFont(15, weight: .semibold))
                    .foregroundStyle(DS.textPrimary)
                if let dist = tracker.distanceToDropoffKm {
                    Text(String(format: "%.0f m remaining", dist * 1000))
                        .font(DS.monoFont(11))
                        .foregroundStyle(DS.textSecondary)
                }
            }
            Spacer()
        }
    }

    // MARK: - Taxi guidance

    private var taxiGuidance: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(DS.orange).frame(width: 40, height: 40)
                Image(systemName: option.provider.iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("En route via \(option.provider.displayName)")
                    .font(DS.bodyFont(15, weight: .semibold))
                    .foregroundStyle(DS.textPrimary)
                Text("Relax — your driver knows the way")
                    .font(DS.bodyFont(12))
                    .foregroundStyle(DS.textSecondary)
            }
            Spacer()
        }
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DS.surfaceRaised).frame(height: 4)
                    Capsule().fill(DS.orange)
                        .frame(width: geo.size.width * tracker.progress, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, DS.margin)
        .padding(.top, 8)
    }

    // MARK: - ETA footer

    private var etaFooter: some View {
        HStack {
            HStack(spacing: 5) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                Text(tracker.etaText)
                    .font(DS.monoFont(11))
            }
            .foregroundStyle(DS.textSecondary)

            Spacer()

            Text("Passive guidance — not navigation")
                .font(DS.monoFont(9))
                .foregroundStyle(DS.textTertiary)
        }
        .padding(.horizontal, DS.margin)
        .padding(.top, 8)
    }
}

// MARK: - Journey Tracker

@MainActor
final class JourneyTracker: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var nearestStation: MetroStation?
    @Published var alightStation: MetroStation?
    @Published var distanceToDropoffKm: Double?
    @Published var progress: Double = 0
    @Published var etaText: String = "--"

    private let manager = CLLocationManager()
    private var dropoff: CLLocation?
    private var pickup: CLLocation?
    private var option: QuoteOption?
    private var totalDistanceKm: Double = 1

    func start(option: QuoteOption, pickup: CLLocation, dropoff: CLLocation) {
        self.option = option
        self.pickup = pickup
        self.dropoff = dropoff
        self.totalDistanceKm = pickup.distance(from: dropoff) / 1000
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.startUpdatingLocation()
    }

    func stop() { manager.stopUpdatingLocation() }

    fileprivate func update(location: CLLocation) {
        currentLocation = location
        guard let dropoff else { return }

        let distKm = location.distance(from: dropoff) / 1000
        distanceToDropoffKm = distKm

        // Progress: how far along we've come from pickup
        if let pickup {
            let covered = pickup.distance(from: location) / 1000
            progress = min(covered / totalDistanceKm, 1.0)
        }

        // ETA
        let remaining = distKm / 5.0 * 60 // rough
        etaText = remaining < 1 ? "Arriving" : "\(Int(remaining)) min remaining"

        // Metro station detection
        if option?.provider == .rtaMetro || option?.provider == .rtaBus {
            let nearest = MetroStation.nearest(to: location.coordinate, max: 1).first
            if let nearest, nearest.clLocation.distance(from: location) < 500 {
                nearestStation = nearest
            }
            // Alight station: station nearest to dropoff
            alightStation = MetroStation.nearest(to: dropoff.coordinate, max: 1).first
        }
    }
}

extension JourneyTracker: CLLocationManagerDelegate {
    nonisolated func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.last else { return }
        Task { @MainActor in self.update(location: loc) }
    }
}

// MARK: - Tracking Map

struct TrackingMapView: UIViewRepresentable {
    let userLocation: CLLocationCoordinate2D?
    let pickup: CLLocationCoordinate2D
    let dropoff: CLLocationCoordinate2D
    let nearestStation: MetroStation?

    func makeUIView(context: Context) -> MKMapView {
        let m = MKMapView()
        m.delegate = context.coordinator
        m.showsUserLocation = true
        return m
    }

    func updateUIView(_ m: MKMapView, context: Context) {
        m.removeAnnotations(m.annotations.filter { !($0 is MKUserLocation) })
        m.removeOverlays(m.overlays)

        let dest = MKPointAnnotation()
        dest.coordinate = dropoff; dest.title = "Destination"
        m.addAnnotation(dest)

        if let s = nearestStation {
            let pin = MKPointAnnotation()
            pin.coordinate = s.coordinate; pin.title = s.name
            m.addAnnotation(pin)
        }

        let req = MKDirections.Request()
        req.source = MKMapItem(placemark: MKPlacemark(coordinate: pickup))
        req.destination = MKMapItem(placemark: MKPlacemark(coordinate: dropoff))
        req.transportType = .automobile
        MKDirections(request: req).calculate { r, _ in
            guard let route = r?.routes.first else { return }
            DispatchQueue.main.async { m.addOverlay(route.polyline) }
        }

        if let ul = userLocation {
            m.setCenter(ul, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ m: MKMapView, rendererFor o: MKOverlay) -> MKOverlayRenderer {
            guard let p = o as? MKPolyline else { return MKOverlayRenderer(overlay: o) }
            let r = MKPolylineRenderer(polyline: p)
            r.strokeColor = UIColor(DS.orange); r.lineWidth = 4; return r
        }
    }
}

// MARK: - Rounded corner shape helper

struct RoundedCorners: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let p = UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                              cornerRadii: CGSize(width: radius, height: radius))
        return Path(p.cgPath)
    }
}
