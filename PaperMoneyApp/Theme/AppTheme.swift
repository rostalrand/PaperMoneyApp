import SwiftUI

public struct AppTheme {
    public struct Colors {
        // Canvas & Surfaces
        public static let obsidianCanvas = Color(hex: "#080A0F")
        public static let canvas = Color(hex: "#080A0F")
        public static let cardSurface = Color(hex: "#11141D")
        public static let elevatedSurface = Color(hex: "#181C26")
        public static let cardHighlight = Color(hex: "#181C26")
        public static let cardBorder = Color.white.opacity(0.06)
        
        // Brand & Accents
        public static let gain = Color(hex: "#00C805")
        public static let loss = Color(hex: "#FF3B30")
        public static let gainBadge = Color(hex: "#00C805").opacity(0.15)
        public static let lossBadge = Color(hex: "#FF3B30").opacity(0.15)
        
        // Text & Hierarchies
        public static let headline = Color.white
        public static let subheadline = Color(hex: "#8E92A0")
        public static let secondaryText = Color(hex: "#8E92A0")
        public static let tertiaryText = Color(hex: "#5A5E6B")
        public static let muted = Color(hex: "#5A5E6B")
    }
    
    public struct Fonts {
        public static let heroBalance = Font.system(size: 38, weight: .bold, design: .rounded)
        public static let priceLarge = Font.system(size: 32, weight: .heavy, design: .rounded)
        public static let tickerSymbol = Font.system(size: 17, weight: .bold, design: .rounded)
        public static let bodyBold = Font.system(size: 15, weight: .semibold, design: .rounded)
        public static let captionMedium = Font.system(size: 12, weight: .medium, design: .rounded)
        public static let microBadge = Font.system(size: 11, weight: .bold, design: .rounded)
        public static let keypadNumber = Font.system(size: 26, weight: .semibold, design: .rounded)
    }
}

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

public struct FintechCardModifier: ViewModifier {
    public var cornerRadius: CGFloat = 16
    public var padding: CGFloat = 16

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.Colors.cardSurface)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
            )
    }
}

public extension View {
    func fintechCard(cornerRadius: CGFloat = 16, padding: CGFloat = 16) -> some View {
        self.modifier(FintechCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}
