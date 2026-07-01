import SwiftUI

// MARK: - TransitGo Design System — Orange Brand

enum DS {
    // Core palette
    static let orange         = Color(hex: "FF6B00")   // primary brand
    static let orangeDim      = Color(hex: "FF6B00").opacity(0.15)
    static let bg             = Color(hex: "0D0D0D")
    static let surface        = Color(hex: "1A1A1A")
    static let surfaceRaised  = Color(hex: "252525")
    static let border         = Color(hex: "2C2C2E")

    // Text
    static let textPrimary    = Color.white
    static let textSecondary  = Color.white.opacity(0.55)
    static let textTertiary   = Color.white.opacity(0.28)

    // Provider brand colours (used only for icon/dot — not section chrome)
    static let careemGreen    = Color(hex: "00A651")
    static let rtaBlue        = Color(hex: "1B6EC2")
    static let zedAmber       = Color(hex: "F5A623")
    static let yangoRed       = Color(hex: "FC3F1D")
    static let walkGray       = Color(hex: "8E8E93")

    // Spacing
    static let gutter: CGFloat  = 16
    static let margin: CGFloat  = 20

    // Typography — swap Font.system for Font.custom once Anton/Archivo fonts added
    static func displayFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black)
    }
    static func bodyFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
    static func monoFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

// MARK: - Hex colour init

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        self.init(
            red:   Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8)  & 0xFF) / 255,
            blue:  Double(int         & 0xFF) / 255
        )
    }
}

// MARK: - Provider brand colour

extension Provider {
    var brandColor: Color {
        switch self {
        case .hala, .careem: return DS.careemGreen
        case .zed:           return DS.zedAmber
        case .uber:          return .white
        case .yango:         return DS.yangoRed
        case .rtaMetro, .rtaBus, .rtaTaxi: return DS.rtaBlue
        case .walking:       return DS.walkGray
        }
    }
}

let kCardHeight: CGFloat = 72
