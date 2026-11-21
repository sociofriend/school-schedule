import SwiftUI

/// The kid's chosen look (branding concepts): colors, type and app icon.
enum AppTheme: String, CaseIterable, Identifiable {
    case apricot, chalkboard, star

    var id: String { rawValue }

    var name: String {
        switch self {
        case .apricot: "Ծիրան"
        case .chalkboard: "Կավիճ"
        case .star: "Աստղիկ"
        }
    }

    var tagline: String {
        switch self {
        case .apricot: "Արևոտ և ջերմ"
        case .chalkboard: "Հանգիստ դասարան"
        case .star: "Տիեզերական արկած"
        }
    }

    var symbol: String {
        switch self {
        case .apricot: "sun.max.fill"
        case .chalkboard: "pencil.and.scribble"
        case .star: "sparkles"
        }
    }

    var accent: Color {
        switch self {
        case .apricot: Color(rgb: 0xFF7A3D)
        case .chalkboard: Color(rgb: 0xFFD95A)
        case .star: Color(rgb: 0xFF4F86)
        }
    }

    /// Screen background behind cards.
    var background: Color {
        switch self {
        case .apricot: Color(rgb: 0xFFF8EC)
        case .chalkboard: Color(rgb: 0x173D2E)
        case .star: Color(rgb: 0x2B1B6B)
        }
    }

    /// Card surface on top of `background`.
    var surface: Color {
        switch self {
        case .apricot: .white
        case .chalkboard: Color(rgb: 0x22553F)
        case .star: Color(rgb: 0x3D2A8A)
        }
    }

    /// Text/icon color on top of `accent` (yellow chalk needs dark text).
    var onAccent: Color { self == .chalkboard ? Color(rgb: 0x173D2E) : .white }

    var colorScheme: ColorScheme { self == .apricot ? .light : .dark }

    var fontDesign: Font.Design {
        switch self {
        case .apricot: .rounded
        case .chalkboard: .serif
        case .star: .default
        }
    }

    var fontWidth: Font.Width { self == .star ? .condensed : .standard }

    /// Alternate icon set in the asset catalog; `nil` is the primary `AppIcon`.
    var iconName: String? {
        switch self {
        case .apricot: nil
        case .chalkboard: "AppIconChalkboard"
        case .star: "AppIconStar"
        }
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.apricot
}

extension EnvironmentValues {
    var theme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    /// Applies the theme to a whole screen tree: tint, color scheme, type and `\.theme`.
    func themed(_ theme: AppTheme) -> some View {
        environment(\.theme, theme)
            .tint(theme.accent)
            .preferredColorScheme(theme.colorScheme)
            .fontDesign(theme.fontDesign)
            .fontWidth(theme.fontWidth)
    }
}

extension Color {
    /// `0xRRGGBB` in sRGB.
    init(rgb: UInt32) {
        self.init(.sRGB, red: Double((rgb >> 16) & 0xFF) / 255,
                  green: Double((rgb >> 8) & 0xFF) / 255, blue: Double(rgb & 0xFF) / 255)
    }
}
