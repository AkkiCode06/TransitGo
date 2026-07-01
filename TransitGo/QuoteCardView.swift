import SwiftUI

struct QuoteCardView: View {
    let option: QuoteOption
    let prefs: UserPreferences
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {

                // Brand stripe
                Rectangle()
                    .fill(option.provider.brandColor)
                    .frame(width: 3)

                // Icon block
                ZStack {
                    option.provider.brandColor.opacity(0.08)
                    Image(systemName: option.provider.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(option.provider.brandColor)
                }
                .frame(width: 48)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(option.provider.displayName)
                            .font(DS.bodyFont(14, weight: .semibold))
                            .foregroundStyle(DS.textPrimary)
                        tierPill
                        subscriptionPill
                    }
                    HStack(spacing: 8) {
                        if let eta = option.etaMinutes {
                            metaLabel("\(eta) min away")
                        }
                        if let t = option.travelMinutes {
                            metaLabel("\(t) min trip")
                        }
                    }
                }
                .padding(.horizontal, 12)

                Spacer(minLength: 8)

                // Fare
                VStack(alignment: .trailing, spacing: 3) {
                    fareLabel
                    if option.bucket == .handoff {
                        Text("EST.")
                            .font(DS.monoFont(9))
                            .foregroundStyle(DS.textTertiary)
                    }
                }
                .padding(.trailing, DS.gutter)
            }
            .frame(height: kCardHeight)
            .background(DS.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DS.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Fare

    @ViewBuilder
    private var fareLabel: some View {
        if let _ = option.fareMin {
            Text(option.fareDisplay)
                .font(DS.displayFont(18))
                .foregroundStyle(DS.textPrimary)
        } else {
            Text("Open app →")
                .font(DS.bodyFont(13, weight: .medium))
                .foregroundStyle(option.provider.brandColor)
        }
    }

    // MARK: - Badges

    @ViewBuilder
    private var tierPill: some View {
        let label: String? = {
            switch option.provider {
            case .hala, .zed, .rtaTaxi:  return "ECONOMY"
            case .uber:                   return "UBERX"
            case .careem:                 return "GO"
            case .rtaMetro:               return "METRO"
            case .rtaBus:                 return "BUS"
            case .yango:                  return "ECONOM"
            case .walking:                return "WALK"
            }
        }()
        if let l = label {
            Text(l)
                .font(DS.monoFont(8))
                .foregroundStyle(option.provider.brandColor.opacity(0.9))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(option.provider.brandColor.opacity(0.12))
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private var subscriptionPill: some View {
        if option.provider == .hala && prefs.careemPlusActive {
            Text("PLUS")
                .font(DS.monoFont(8))
                .foregroundStyle(.white)
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(DS.careemGreen)
                .clipShape(Capsule())
        } else if option.provider == .uber && prefs.uberOneActive {
            Text("ONE")
                .font(DS.monoFont(8))
                .foregroundStyle(DS.bg)
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(.white)
                .clipShape(Capsule())
        }
    }

    private func metaLabel(_ text: String) -> some View {
        Text(text)
            .font(DS.monoFont(10))
            .foregroundStyle(DS.textSecondary)
    }
}

// MARK: - Disclaimer card (shown below a card when it has a disclaimer)

struct DisclaimerRow: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
                .padding(.top, 4)
            Text(text)
                .font(DS.bodyFont(11))
                .foregroundStyle(DS.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, DS.gutter)
        .padding(.vertical, 6)
    }
}
