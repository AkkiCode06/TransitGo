import SwiftUI

// MARK: - Journey Results View

struct JourneyResultsView: View {
    @ObservedObject var vm: TripViewModel
    @ObservedObject var prefs: UserPreferences
    let onTrack: (QuoteOption) -> Void

    @State private var expandedID: UUID?

    // All sorted by total door-to-door time (LocalFareEngine already sorts, but enforce here too)
    private var sorted: [QuoteOption] { vm.quotes.sorted { $0.totalMinutes < $1.totalMinutes } }

    private var cheapest: QuoteOption? { vm.quotes.filter { $0.fareMin != nil }.min { ($0.fareMin ?? 0) < ($1.fareMin ?? 0) } }
    private var fastest:  QuoteOption? { sorted.first }

    var body: some View {
        VStack(spacing: 0) {
            // Destination + route summary
            destinationHeader

            // Option list
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, opt in
                        JourneyOptionRow(
                            option: opt,
                            prefs: prefs,
                            isFastest: opt.id == fastest?.id && idx == 0,
                            isCheapest: opt.id == cheapest?.id,
                            isExpanded: expandedID == opt.id,
                            onTap: {
                                withAnimation(.spring(response: 0.3)) {
                                    expandedID = expandedID == opt.id ? nil : opt.id
                                }
                            },
                            onBook: { vm.openProvider(opt) },
                            onTrack: { onTrack(opt) }
                        )
                        if idx < sorted.count - 1 {
                            Divider().background(DS.border)
                        }
                    }
                }
                .padding(.bottom, 80) // room for bottom bar
            }

            // Bottom stats bar
            bottomBar
        }
    }

    // MARK: - Destination header

    private var destinationHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.dropoffLabel)
                        .font(DS.bodyFont(20, weight: .bold))
                        .foregroundStyle(DS.textPrimary)
                        .lineLimit(1)
                    if let r = vm.routeInfo {
                        HStack(spacing: 10) {
                            Label(String(format: "%.1f km", r.distanceKm), systemImage: "arrow.left.and.right")
                            Label("\(Int(r.durationMin)) min drive", systemImage: "car")
                            if r.isAirportPickup {
                                Label("Airport", systemImage: "airplane").foregroundStyle(DS.orange)
                            }
                        }
                        .font(DS.monoFont(10))
                        .foregroundStyle(DS.textTertiary)
                        .labelStyle(.titleAndIcon)
                    }
                }
                Spacer()
                Text("\(sorted.count) options")
                    .font(DS.monoFont(10))
                    .foregroundStyle(DS.orange)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(DS.orange.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, DS.margin)
            .padding(.vertical, 12)
            .background(DS.bg)

            Rectangle().fill(DS.orange).frame(height: 1).opacity(0.25)
        }
    }

    // MARK: - Bottom stats bar

    private var bottomBar: some View {
        HStack(spacing: 0) {
            if let c = cheapest {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CHEAPEST").font(DS.monoFont(9)).foregroundStyle(DS.textTertiary)
                    HStack(spacing: 4) {
                        Image(systemName: c.provider.iconName).font(.system(size: 11))
                        Text("\(c.provider.displayName)  \(c.fareDisplay)")
                            .font(DS.bodyFont(13, weight: .semibold))
                    }
                    .foregroundStyle(c.provider.brandColor)
                }
                .padding(.leading, DS.margin)
            }
            Spacer()
            Rectangle().fill(DS.border).frame(width: 1, height: 32)
            if let f = fastest {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("FASTEST").font(DS.monoFont(9)).foregroundStyle(DS.textTertiary)
                    HStack(spacing: 4) {
                        Text("\(f.totalMinutes) min  \(f.provider.displayName)")
                            .font(DS.bodyFont(13, weight: .semibold))
                        Image(systemName: "bolt.fill").font(.system(size: 11))
                    }
                    .foregroundStyle(DS.orange)
                }
                .padding(.trailing, DS.margin)
            }
        }
        .frame(height: 56)
        .background(.ultraThinMaterial)
        .overlay(Divider().background(DS.border), alignment: .top)
    }
}

// MARK: - Journey Option Row

struct JourneyOptionRow: View {
    let option: QuoteOption
    let prefs: UserPreferences
    let isFastest: Bool
    let isCheapest: Bool
    let isExpanded: Bool
    let onTap: () -> Void
    let onBook: () -> Void
    let onTrack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            Button(action: onTap) {
                HStack(spacing: 0) {
                    // Orange vertical line + colored node
                    VStack(spacing: 0) {
                        Rectangle().fill(DS.orange.opacity(0.25)).frame(width: 2).frame(maxHeight: .infinity)
                        ZStack {
                            Circle().fill(DS.bg).frame(width: 16, height: 16)
                            Circle().fill(option.provider.brandColor).frame(width: 11, height: 11)
                        }
                        Rectangle().fill(DS.orange.opacity(0.25)).frame(width: 2).frame(maxHeight: .infinity)
                    }
                    .frame(width: 36)

                    // Content
                    HStack(alignment: .center, spacing: 0) {
                        // Left: icon + name + meta
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 8) {
                                // Category icon
                                Image(systemName: option.provider.iconName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(option.provider.brandColor)
                                    .frame(width: 20)

                                Text(option.provider.displayName)
                                    .font(DS.bodyFont(15, weight: .semibold))
                                    .foregroundStyle(DS.textPrimary)

                                // Badges
                                if isFastest {
                                    badge("FASTEST", color: DS.orange)
                                }
                                if isCheapest && !isFastest {
                                    badge("CHEAPEST", color: DS.careemGreen)
                                }
                                if option.bucket == .priced && !isFastest {
                                    badge("NO SURGE", color: DS.rtaBlue)
                                }
                            }

                            // Meta
                            HStack(spacing: 10) {
                                if let eta = option.etaMinutes, eta > 0 {
                                    metaItem(icon: "clock", text: "\(eta) min wait")
                                }
                                if let t = option.travelMinutes {
                                    metaItem(icon: option.provider == .walking ? "figure.walk" : "arrow.right",
                                             text: "\(t) min trip")
                                }
                                metaItem(icon: "timer", text: "\(option.totalMinutes) min total",
                                         bold: true, color: DS.orange.opacity(0.85))
                            }
                        }
                        .padding(.vertical, 14)

                        Spacer()

                        // Right: fare + chevron
                        VStack(alignment: .trailing, spacing: 3) {
                            if let _ = option.fareMin {
                                Text(option.fareDisplay)
                                    .font(DS.bodyFont(16, weight: .bold))
                                    .foregroundStyle(DS.textPrimary)
                            } else {
                                Text("Open app")
                                    .font(DS.bodyFont(13, weight: .medium))
                                    .foregroundStyle(option.provider.brandColor)
                            }
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(DS.textTertiary)
                        }
                        .padding(.trailing, DS.margin)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded detail
            if isExpanded {
                expandedDetail
                    .transition(.asymmetric(
                        insertion: .push(from: .top).combined(with: .opacity),
                        removal: .push(from: .bottom).combined(with: .opacity)
                    ))
            }
        }
    }

    // MARK: - Expanded detail

    private var expandedDetail: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Disclaimer
            if let d = option.disclaimer {
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(option.provider.brandColor).frame(width: 5, height: 5).padding(.top, 4)
                    Text(d)
                        .font(DS.bodyFont(11))
                        .foregroundStyle(DS.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Action buttons
            HStack(spacing: 10) {
                // Track / guidance button (transit + walking)
                if option.provider == .rtaMetro || option.provider == .rtaBus || option.provider == .walking {
                    Button(action: onTrack) {
                        Label("Track Journey", systemImage: "location.fill")
                            .font(DS.bodyFont(13, weight: .semibold))
                            .foregroundStyle(DS.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(DS.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                // Book / open button
                if option.bucket == .handoff || option.appStoreURL != nil {
                    Button(action: onBook) {
                        Label(option.bucket == .handoff ? "Open App" : "Book",
                              systemImage: "arrow.up.right")
                            .font(DS.bodyFont(13, weight: .semibold))
                            .foregroundStyle(DS.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(DS.surfaceRaised)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.border, lineWidth: 1))
                    }
                }
            }
        }
        .padding(.horizontal, DS.margin)
        .padding(.leading, 36)   // align with content area (past the line)
        .padding(.bottom, 14)
        .padding(.top, 4)
        .background(DS.surface.opacity(0.5))
    }

    // MARK: - Helpers

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(DS.monoFont(8))
            .foregroundStyle(color)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 1))
    }

    private func metaItem(icon: String, text: String, bold: Bool = false, color: Color = DS.textSecondary) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(bold ? DS.monoFont(10) : DS.bodyFont(11))
        }
        .foregroundStyle(color)
    }
}
