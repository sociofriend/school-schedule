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

    // Every color is a light/dark pair, so each theme works in both appearances.

    var accent: Color {
        switch self {
        case .apricot: .dynamic(light: 0xEE5A24, dark: 0xFF8A4C)
        case .chalkboard: .dynamic(light: 0x1E7A52, dark: 0xFFD95A)
        case .star: .dynamic(light: 0xD93673, dark: 0xFF5A8E)
        }
    }

    /// Screen background behind cards.
    var background: Color {
        switch self {
        case .apricot: .dynamic(light: 0xFFF6E9, dark: 0x1C1511)
        case .chalkboard: .dynamic(light: 0xEEF5EF, dark: 0x153828)
        case .star: .dynamic(light: 0xF3EFFF, dark: 0x22165A)
        }
    }

    /// Card surface on top of `background`.
    var surface: Color {
        switch self {
        case .apricot: .dynamic(light: 0xFFFFFF, dark: 0x2B211A)
        case .chalkboard: .dynamic(light: 0xFFFFFF, dark: 0x1F4D39)
        case .star: .dynamic(light: 0xFFFFFF, dark: 0x352684)
        }
    }

    /// Text/icon color on top of `accent`; each pair meets at least 3:1 contrast (large bold text).
    var onAccent: Color {
        switch self {
        case .apricot: .dynamic(light: 0xFFFFFF, dark: 0x1C1511)
        case .chalkboard: .dynamic(light: 0xFFFFFF, dark: 0x153828)
        case .star: .dynamic(light: 0xFFFFFF, dark: 0x1A0E3D)
        }
    }

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
    /// Applies the theme to a whole screen tree: tint, appearance, type and `\.theme`.
    /// A `nil` theme stays neutral (system colors), e.g. before the kid has picked one.
    func themed(_ theme: AppTheme?, appearance: Appearance = .system) -> some View {
        environment(\.theme, theme ?? .apricot)
            .tint(theme?.accent)
            .preferredColorScheme(appearance.colorScheme)
            .fontDesign(theme?.fontDesign ?? .rounded)
            .fontWidth(theme?.fontWidth)
    }
}

/// Light, dark, or follow the system.
enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "Ավտո"
        case .light: "Լույս"
        case .dark: "Մութ"
        }
    }

    var symbol: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.stars.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Segmented light / dark / auto switch.
struct AppearancePicker: View {
    @Binding var selection: Appearance

    var body: some View {
        Picker("Տեսք", selection: $selection) {
            ForEach(Appearance.allCases) { Label($0.title, systemImage: $0.symbol).tag($0) }
        }
        .pickerStyle(.segmented)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

extension Color {
    /// Resolves per trait collection: `light` in light mode, `dark` in dark mode.
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(Color(rgb: dark)) : UIColor(Color(rgb: light)) })
    }

    /// `0xRRGGBB` in sRGB.
    init(rgb: UInt32) {
        self.init(.sRGB, red: Double((rgb >> 16) & 0xFF) / 255,
                  green: Double((rgb >> 8) & 0xFF) / 255, blue: Double(rgb & 0xFF) / 255)
    }
}
