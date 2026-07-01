import SwiftUI

// UAE Transport Directory — providers kept separate from the main comparison screen
// to comply with Uber's anti-competition terms. Listed as an educational resource.

struct DirectoryView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {

                VStack(alignment: .leading, spacing: 4) {
                    Text("Directory")
                        .font(DS.bodyFont(28, weight: .bold))
                        .foregroundStyle(DS.textPrimary)
                    Text("Additional UAE transport providers")
                        .font(DS.bodyFont(14))
                        .foregroundStyle(DS.textSecondary)
                }
                .padding(.top, 8)

                providerSection(
                    title: "RIDE-HAILING",
                    providers: rideHailingProviders
                )
                providerSection(
                    title: "LUXURY & VIP",
                    providers: luxuryProviders
                )
                providerSection(
                    title: "WATER & MARINE",
                    providers: marineProviders
                )

                // Compliance note
                HStack(alignment: .top, spacing: 10) {
                    Circle().fill(DS.orange).frame(width: 5, height: 5).padding(.top, 5)
                    Text("Providers listed here are for reference only. TransitGo does not compare their live prices or handle booking — tap any entry to open their native app or App Store page.")
                        .font(DS.bodyFont(12))
                        .foregroundStyle(DS.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(DS.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.border, lineWidth: 1))

                Spacer(minLength: 40)
            }
            .padding(.horizontal, DS.margin)
            .padding(.bottom, 20)
        }
        .background(DS.bg)
    }

    private func providerSection(title: String, providers: [DirectoryProvider]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(DS.monoFont(10))
                .foregroundStyle(DS.textTertiary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(providers) { p in
                    DirectoryRow(provider: p)
                    if p.id != providers.last?.id {
                        Divider().background(DS.border).padding(.leading, 64)
                    }
                }
            }
            .background(DS.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.border, lineWidth: 1))
        }
    }
}

// MARK: - Row

struct DirectoryRow: View {
    let provider: DirectoryProvider

    var body: some View {
        Button {
            if let url = URL(string: provider.appStoreURL) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 0) {
                // Brand stripe
                Rectangle()
                    .fill(provider.brandColor)
                    .frame(width: 3)

                // Icon
                ZStack {
                    provider.brandColor.opacity(0.10)
                    Image(systemName: provider.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(provider.brandColor)
                }
                .frame(width: 52)

                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(provider.name)
                        .font(DS.bodyFont(14, weight: .semibold))
                        .foregroundStyle(DS.textPrimary)
                    Text(provider.tagline)
                        .font(DS.bodyFont(12))
                        .foregroundStyle(DS.textSecondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)

                Spacer()

                Text("Open →")
                    .font(DS.monoFont(11))
                    .foregroundStyle(provider.brandColor)
                    .padding(.trailing, DS.gutter)
            }
            .frame(height: kCardHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Data

struct DirectoryProvider: Identifiable {
    let id = UUID()
    let name: String
    let tagline: String
    let icon: String
    let brandColor: Color
    let appStoreURL: String
}

private let rideHailingProviders: [DirectoryProvider] = [
    .init(name: "Yango",  tagline: "Economy · Comfort · Business tiers",
          icon: "car.fill",   brandColor: DS.yangoRed,
          appStoreURL: "https://apps.apple.com/ae/app/yango-taxi/id1239899024"),
    .init(name: "XXRide", tagline: "Regular · Select · Luxury · Family",
          icon: "car.fill",   brandColor: Color(hex: "3B82F6"),
          appStoreURL: "https://apps.apple.com/ae/app/xxride/id1580576183"),
]

private let luxuryProviders: [DirectoryProvider] = [
    .init(name: "Blacklane", tagline: "VIP chauffeur · Pre-booked",
          icon: "car.fill",      brandColor: Color(hex: "888888"),
          appStoreURL: "https://apps.apple.com/ae/app/blacklane-professional-rides/id584222905"),
]

private let marineProviders: [DirectoryProvider] = [
    .init(name: "RTA Water Taxi", tagline: "Dubai Creek · Marina · Nol accepted",
          icon: "ferry.fill",       brandColor: DS.rtaBlue,
          appStoreURL: "https://apps.apple.com/ae/app/s-hail/id1111549338"),
    .init(name: "Dubai Tram",     tagline: "Al Sufouh · JBR · Marina corridor",
          icon: "tram.fill",        brandColor: DS.rtaBlue,
          appStoreURL: "https://apps.apple.com/ae/app/s-hail/id1111549338"),
]
