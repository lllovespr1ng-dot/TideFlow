import SwiftUI

// MARK: - Ocean colour palette
extension Color {
    /// Pale aqua-white background
    static let tideBg      = Color(hex: "EFF8F8")
    /// Clear tropical teal — primary accent
    static let tideTeal    = Color(hex: "3AADA8")
    /// Soft seafoam — secondary accent & labels
    static let tideSeafoam = Color(hex: "A8D8D8")
    /// Warm sand — card backgrounds
    static let tideSand    = Color(hex: "F5EDDC")
    /// Deep ocean — primary text
    static let tideDeep    = Color(hex: "1A3535")
    /// Very light teal — ring track / dividers
    static let tideMist    = Color(hex: "D4EEEE")
}

// MARK: - Hex initialiser
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
