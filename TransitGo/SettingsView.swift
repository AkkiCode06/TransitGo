import SwiftUI

struct SettingsView: View {
    @ObservedObject var prefs: UserPreferences

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {

                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(DS.bodyFont(28, weight: .bold))
                        .foregroundStyle(DS.textPrimary)
                    Text("Personalise your fare estimates")
                        .font(DS.bodyFont(14))
                        .foregroundStyle(DS.textSecondary)
                }
                .padding(.top, 8)

                // Tolls
                settingSection(title: "TOLL GATES") {
                    SettingsToggleRow(
                        label: "Include Salik Tolls",
                        sublabel: "Adds AED 4 per gate to metered fare estimates",
                        icon: "road.lanes",
                        accentColor: DS.orange,
                        isOn: $prefs.includeSalik
                    )
                }

                // Subscriptions
                settingSection(title: "SUBSCRIPTIONS") {
                    SettingsToggleRow(
                        label: "Careem Plus",
                        sublabel: "~10% off Hala taxi fares (verify current terms in Careem app)",
                        icon: "checkmark.seal.fill",
                        accentColor: DS.careemGreen,
                        isOn: $prefs.careemPlusActive
                    )
                    Divider().background(DS.border).padding(.leading, 56)
                    SettingsToggleRow(
                        label: "Uber One",
                        sublabel: "~5% off Uber estimates (verify current terms in Uber app)",
                        icon: "checkmark.seal.fill",
                        accentColor: .white,
                        isOn: $prefs.uberOneActive
                    )
                }

                // About
                settingSection(title: "ABOUT") {
                    infoRow("Fare engine", value: "RTA tariff · local math")
                    Divider().background(DS.border).padding(.leading, 16)
                    infoRow("Uber estimates", value: "Independent (no Uber API)")
                    Divider().background(DS.border).padding(.leading, 16)
                    infoRow("Salik rate", value: "AED 4/gate [VERIFY]")
                    Divider().background(DS.border).padding(.leading, 16)
                    infoRow("Version", value: "0.1.0 (beta)")
                }

                // Disclaimer
                HStack(alignment: .top, spacing: 10) {
                    Circle().fill(DS.orange).frame(width: 5, height: 5).padding(.top, 5)
                    Text("Subscription discounts are approximate estimates. Always verify current benefits in the provider's app. TransitGo is not affiliated with Careem, Uber, or any provider listed.")
                        .font(DS.bodyFont(12))
                        .foregroundStyle(DS.textTertiary)
                }
                .padding(14)
                .background(DS.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.border, lineWidth: 1))
            }
            .padding(.horizontal, DS.margin)
            .padding(.bottom, 40)
        }
        .background(DS.bg)
    }

    private func settingSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(DS.monoFont(10))
                .foregroundStyle(DS.textTertiary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(DS.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.border, lineWidth: 1))
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(DS.bodyFont(14))
                .foregroundStyle(DS.textPrimary)
            Spacer()
            Text(value)
                .font(DS.monoFont(11))
                .foregroundStyle(DS.textSecondary)
        }
        .padding(.horizontal, DS.gutter)
        .padding(.vertical, 13)
    }
}

struct SettingsToggleRow: View {
    let label: String
    let sublabel: String
    let icon: String
    let accentColor: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(DS.bodyFont(14, weight: .medium))
                    .foregroundStyle(DS.textPrimary)
                Text(sublabel)
                    .font(DS.bodyFont(11))
                    .foregroundStyle(DS.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().tint(accentColor)
        }
        .padding(.horizontal, DS.gutter)
        .padding(.vertical, 12)
    }
}
