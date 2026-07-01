import SwiftUI
import MapKit

// MARK: - Shell

struct ContentView: View {
    @StateObject private var locationService: LocationService
    @StateObject private var vm: TripViewModel
    @StateObject private var search = LocationSearchService()
    @StateObject private var prefs  = UserPreferences()

    init(locationService: LocationService? = nil) {
        let loc = locationService ?? LocationService()
        _locationService = StateObject(wrappedValue: loc)
        _vm = StateObject(wrappedValue: TripViewModel(locationService: loc))
    }

    var body: some View {
        TabView {
            PlannerTab(vm: vm, search: search, prefs: prefs)
                .tabItem { Label("Plan", systemImage: "map.fill") }
            DirectoryView()
                .tabItem { Label("Directory", systemImage: "list.bullet.rectangle") }
            SettingsView(prefs: prefs)
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
        }
        .tint(DS.orange)
        .preferredColorScheme(.dark)
        .onAppear {
            locationService.requestWhenInUse()
            vm.prefs = prefs
            var a = UITabBarAppearance()
            a.configureWithOpaqueBackground()
            a.backgroundColor = UIColor(DS.surface)
            UITabBar.appearance().standardAppearance   = a
            UITabBar.appearance().scrollEdgeAppearance = a
        }
    }
}

// MARK: - Planner Tab (map + full-width custom sheet)

struct PlannerTab: View {
    @ObservedObject var vm: TripViewModel
    @ObservedObject var search: LocationSearchService
    @ObservedObject var prefs: UserPreferences

    // Sheet snap heights
    private let snapSmall:  CGFloat = 210
    private let snapMedium: CGFloat = 480
    private let snapLarge:  CGFloat = UIScreen.main.bounds.height * 0.88

    @State private var sheetHeight: CGFloat = 210
    @GestureState private var dragDelta: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Full-screen map
            mapLayer.ignoresSafeArea()

            // Custom full-width bottom sheet
            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 38, height: 4)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                PlannerContent(
                    vm: vm, search: search, prefs: prefs,
                    expandSheet: { snap(to: snapMedium) },
                    fullSheet:   { snap(to: snapLarge) }
                )
            }
            .frame(maxWidth: .infinity)
            .frame(height: max(snapSmall, sheetHeight - dragDelta))
            .background(DS.bg)
            .clipShape(RoundedCorners(radius: 22, corners: [.topLeft, .topRight]))
            .gesture(
                DragGesture(minimumDistance: 10)
                    .updating($dragDelta) { val, state, _ in
                        state = val.translation.height
                    }
                    .onEnded { val in
                        let v = val.translation.height
                        if v < -60 {
                            snap(to: sheetHeight < snapMedium ? snapMedium : snapLarge)
                        } else if v > 60 {
                            snap(to: sheetHeight > snapMedium ? snapMedium : snapSmall)
                        }
                    }
            )
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: sheetHeight)
            .ignoresSafeArea(edges: .bottom)
        }
        .onChange(of: vm.state) { _, s in
            if s == .results { snap(to: snapMedium) }
            if s == .idle    { snap(to: snapSmall)  }
        }
    }

    private func snap(to height: CGFloat) { sheetHeight = height }

    // MARK: - Map

    @ViewBuilder
    private var mapLayer: some View {
        if let p = vm.pickupLocation, let d = vm.dropoffLocation {
            MapRouteView(pickup: p.coordinate, dropoff: d.coordinate)
        } else if let p = vm.pickupLocation {
            Map(initialPosition: .region(.init(
                center: p.coordinate,
                span: .init(latitudeDelta: 0.05, longitudeDelta: 0.05))))
            .mapStyle(.standard(elevation: .realistic))
        } else {
            Map(initialPosition: .region(.init(
                center: .init(latitude: 25.2048, longitude: 55.2708),
                span: .init(latitudeDelta: 0.10, longitudeDelta: 0.10))))
            .mapStyle(.standard(elevation: .realistic))
        }
    }
}

// MARK: - Planner Content

struct PlannerContent: View {
    @ObservedObject var vm: TripViewModel
    @ObservedObject var search: LocationSearchService
    @ObservedObject var prefs: UserPreferences

    let expandSheet: () -> Void
    let fullSheet: () -> Void

    @FocusState private var focused: Bool
    @State private var showTracking = false
    @State private var trackingOption: QuoteOption?

    var body: some View {
        VStack(spacing: 0) {
            // Search inputs — always visible
            searchInputs
                .padding(.horizontal, DS.margin)
                .padding(.bottom, 12)

            // Salik + subscription chips
            chipsRow
                .padding(.horizontal, DS.margin)
                .padding(.bottom, 10)

            Divider().background(DS.border)

            // Dynamic content
            Group {
                if focused && !search.suggestions.isEmpty {
                    suggestionsView
                } else {
                    switch vm.state {
                    case .idle:     idleHint
                    case .routing, .loading: loadingView
                    case .results:  resultsContent
                    case .error(let m): errorView(m)
                    }
                }
            }
        }
        .sheet(isPresented: $showTracking) {
            if let opt = trackingOption, let pickup = vm.pickupLocation, let dropoff = vm.dropoffLocation {
                JourneyTrackingView(
                    option: opt, pickup: pickup, dropoff: dropoff,
                    dropoffName: vm.dropoffLabel, isPresented: $showTracking
                )
                .presentationDetents([.height(340), .large])
                .presentationBackground(DS.bg)
                .presentationCornerRadius(22)
            }
        }
    }

    // MARK: - Search inputs

    private var searchInputs: some View {
        HStack(alignment: .center, spacing: 10) {
            // Dot track
            VStack(spacing: 3) {
                Circle().fill(DS.careemGreen).frame(width: 9, height: 9)
                ForEach(0..<4, id: \.self) { _ in
                    Circle().fill(DS.border).frame(width: 3, height: 3)
                }
                Circle()
                    .stroke(DS.orange, lineWidth: 2)
                    .frame(width: 9, height: 9)
            }

            VStack(spacing: 0) {
                // Pickup
                HStack {
                    Text(vm.pickupLabel)
                        .font(DS.bodyFont(14))
                        .foregroundStyle(DS.textSecondary)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.vertical, 11)

                Divider().background(DS.border)

                // Dropoff
                HStack {
                    TextField("Where to?", text: $vm.dropoffQuery)
                        .font(DS.bodyFont(14, weight: .medium))
                        .foregroundStyle(DS.textPrimary)
                        .tint(DS.orange)
                        .submitLabel(.search)
                        .focused($focused)
                        .onChange(of: vm.dropoffQuery) { _, q in
                            search.update(query: q)
                            if !q.isEmpty { expandSheet() }
                        }
                        .onSubmit {
                            search.clear(); focused = false; vm.searchAndRoute()
                        }
                    if !vm.dropoffQuery.isEmpty {
                        Button { vm.dropoffQuery = ""; search.clear() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(DS.textTertiary)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.vertical, 11)
            }
        }
        .padding(DS.gutter)
        .background(DS.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.border, lineWidth: 1))
    }

    // MARK: - Chips

    private var chipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(icon: "road.lanes", label: prefs.includeSalik ? "Salik  ON" : "Salik  OFF",
                     active: prefs.includeSalik) {
                    prefs.includeSalik.toggle()
                    if vm.state == .results { Task { await vm.refreshQuotes() } }
                }
                if vm.state == .results {
                    chip(icon: "arrow.up.arrow.down", label: "Fastest first", active: true) {}
                }
                if prefs.careemPlusActive {
                    chip(icon: "tag.fill", label: "Plus", active: true, color: DS.careemGreen) {}
                }
                if prefs.uberOneActive {
                    chip(icon: "tag.fill", label: "One", active: true, color: .white) {}
                }
                if vm.state != .idle {
                    chip(icon: "xmark", label: "Clear", active: false) {
                        vm.reset(); search.clear(); focused = false
                    }
                }
            }
        }
    }

    private func chip(icon: String, label: String, active: Bool, color: Color = DS.orange, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 10, weight: .semibold))
                Text(label).font(DS.bodyFont(12, weight: .medium))
            }
            .foregroundStyle(active ? color : DS.textSecondary)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(active ? color.opacity(0.12) : DS.surfaceRaised)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(active ? color.opacity(0.35) : DS.border, lineWidth: 1))
        }
    }

    // MARK: - Suggestions

    private var suggestionsView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(search.suggestions, id: \.self) { s in
                    Button {
                        Task {
                            guard let (loc, name) = try? await search.resolve(s) else { return }
                            vm.dropoffQuery = name; search.clear(); focused = false
                            vm.routeTo(dropoff: loc, name: name)
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(DS.textTertiary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(s.title)
                                    .font(DS.bodyFont(14, weight: .medium))
                                    .foregroundStyle(DS.textPrimary)
                                if !s.subtitle.isEmpty {
                                    Text(s.subtitle)
                                        .font(DS.bodyFont(12))
                                        .foregroundStyle(DS.textSecondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, DS.margin)
                        .padding(.vertical, 13)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().background(DS.border).padding(.leading, DS.margin + 36)
                }
            }
        }
    }

    // MARK: - Results

    private var resultsContent: some View {
        JourneyResultsView(vm: vm, prefs: prefs) { opt in
            trackingOption = opt
            showTracking = true
        }
    }

    // MARK: - State views

    private var idleHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(DS.orange.opacity(0.7))
            Text("Enter a destination to see all transport options")
                .font(DS.bodyFont(13))
                .foregroundStyle(DS.textTertiary)
            Spacer()
        }
        .padding(.horizontal, DS.margin)
        .padding(.vertical, 12)
    }

    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView().tint(DS.orange)
            Text(vm.state == .routing ? "Calculating route…" : "Finding all options…")
                .font(DS.bodyFont(13))
                .foregroundStyle(DS.textSecondary)
            Spacer()
        }
        .padding(.horizontal, DS.margin)
        .padding(.vertical, 14)
    }

    private func errorView(_ msg: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(DS.orange)
            Text(msg)
                .font(DS.bodyFont(13))
                .foregroundStyle(DS.textSecondary)
            Spacer()
            Button("Retry") { vm.searchAndRoute() }
                .font(DS.bodyFont(13, weight: .semibold))
                .foregroundStyle(DS.orange)
        }
        .padding(.horizontal, DS.margin)
        .padding(.vertical, 12)
    }
}

// MARK: - Map

struct MapRouteView: UIViewRepresentable {
    let pickup: CLLocationCoordinate2D
    let dropoff: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        let m = MKMapView(); m.delegate = context.coordinator
        m.showsUserLocation = true
        m.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .realistic)
        return m
    }

    func updateUIView(_ m: MKMapView, context: Context) {
        m.removeAnnotations(m.annotations); m.removeOverlays(m.overlays)
        for (title, coord) in [("Pickup", pickup), ("Dropoff", dropoff)] {
            let p = MKPointAnnotation(); p.coordinate = coord; p.title = title
            m.addAnnotation(p)
        }
        let req = MKDirections.Request()
        req.source      = MKMapItem(placemark: MKPlacemark(coordinate: pickup))
        req.destination = MKMapItem(placemark: MKPlacemark(coordinate: dropoff))
        req.transportType = .automobile
        MKDirections(request: req).calculate { r, _ in
            guard let route = r?.routes.first else { return }
            DispatchQueue.main.async {
                m.addOverlay(route.polyline)
                m.setVisibleMapRect(route.polyline.boundingMapRect.insetBy(dx: -8000, dy: -8000), animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ m: MKMapView, rendererFor o: MKOverlay) -> MKOverlayRenderer {
            guard let p = o as? MKPolyline else { return MKOverlayRenderer(overlay: o) }
            let r = MKPolylineRenderer(polyline: p)
            r.strokeColor = UIColor(DS.orange); r.lineWidth = 4; return r
        }
        func mapView(_ m: MKMapView, viewFor a: MKAnnotation) -> MKAnnotationView? {
            guard !a.isKind(of: MKUserLocation.self) else { return nil }
            let v = MKMarkerAnnotationView(annotation: a, reuseIdentifier: "pin")
            v.markerTintColor = a.title == "Pickup" ? UIColor(DS.careemGreen) : UIColor(DS.orange)
            v.glyphTintColor = .white; return v
        }
    }
}

#Preview {
    let loc = LocationService()
    loc.currentLocation = CLLocation(latitude: 25.2048, longitude: 55.2708)
    return ContentView(locationService: loc)
}
