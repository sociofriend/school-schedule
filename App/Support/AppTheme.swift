import SwiftUI

/// The kid's chosen look, one per app logo: colors, type and app icon, each in light and dark.
enum AppTheme: String, CaseIterable, Identifiable {
    case buddy, backpack, letter, scan, clock

    var id: String { rawValue }

    /// Themes from before the logo set map to the closest new one.
    init?(stored raw: String) {
        switch raw {
        case "apricot": self = .buddy
        case "chalkboard": self = .letter
        case "star": self = .clock
        default: self.init(rawValue: raw)
        }
    }

    var name: String {
        switch self {
        case .buddy: "Ընկերիկ"
        case .backpack: "Պայուսակ"
        case .letter: "Դ"
        case .scan: "Սկան"
        case .clock: "Զարթուցիչ"
        }
    }

    var tagline: String {
        switch self {
        case .buddy: "Ժպտացող օրացույց"
        case .backpack: "Պատրաստ ենք դասի"
        case .letter: "Մաքուր և վստահ"
        case .scan: "Նկարիր և վերջ"
        case .clock: "Երեկոյան հիշեցում"
        }
    }

    var symbol: String {
        switch self {
        case .buddy: "face.smiling.inverse"
        case .backpack: "backpack.fill"
        case .letter: "checkmark.seal.fill"
        case .scan: "camera.viewfinder"
        case .clock: "alarm.fill"
        }
    }

    /// Logo image (light/dark) in `Assets.xcassets/ThemeLogos`.
    var logoName: String {
        switch self {
        case .buddy: "LogoBuddy"
        case .backpack: "LogoBackpack"
        case .letter: "LogoLetter"
        case .scan: "LogoScan"
        case .clock: "LogoClock"
        }
    }

    // Every color is a light/dark pair taken from the theme's logo.

    var accent: Color {
        switch self {
        case .buddy: .dynamic(light: 0xE2385F, dark: 0xFF7A93)
        case .backpack: .dynamic(light: 0xD9472B, dark: 0xFF7A59)
        case .letter: .dynamic(light: 0x4B3BE6, dark: 0x8C9BFF)
        case .scan: .dynamic(light: 0x2F55D4, dark: 0x5CE6D8)
        case .clock: .dynamic(light: 0x6A3FC4, dark: 0xFF9A6B)
        }
    }

    /// Screen background behind cards.
    var background: Color {
        switch self {
        case .buddy: .dynamic(light: 0xFFF7DC, dark: 0x1C1606)
        case .backpack: .dynamic(light: 0xE8F8F5, dark: 0x0C1F1E)
        case .letter: .dynamic(light: 0xF1F2FF, dark: 0x110D33)
        case .scan: .dynamic(light: 0xEEF3FC, dark: 0x0A1030)
        case .clock: .dynamic(light: 0xF6F0FF, dark: 0x150D2E)
        }
    }

    /// Card surface on top of `background`.
    var surface: Color {
        switch self {
        case .buddy: .dynamic(light: 0xFFFFFF, dark: 0x2C2410)
        case .backpack: .dynamic(light: 0xFFFFFF, dark: 0x163331)
        case .letter: .dynamic(light: 0xFFFFFF, dark: 0x1D1850)
        case .scan: .dynamic(light: 0xFFFFFF, dark: 0x16204A)
        case .clock: .dynamic(light: 0xFFFFFF, dark: 0x251A4A)
        }
    }

    /// Text/icon color on top of `accent`; white on the light accents, the dark background on the bright dark-mode accents.
    var onAccent: Color {
        switch self {
        case .buddy: .dynamic(light: 0xFFFFFF, dark: 0x1C1606)
        case .backpack: .dynamic(light: 0xFFFFFF, dark: 0x0C1F1E)
        case .letter: .dynamic(light: 0xFFFFFF, dark: 0x110D33)
        case .scan: .dynamic(light: 0xFFFFFF, dark: 0x0A1030)
        case .clock: .dynamic(light: 0xFFFFFF, dark: 0x150D2E)
        }
    }

    var fontDesign: Font.Design {
        switch self {
        case .buddy, .backpack, .clock: .rounded
        case .letter, .scan: .default
        }
    }

    var fontWidth: Font.Width { self == .scan ? .condensed : .standard }

    /// Alternate icon set in the asset catalog (light, dark and tinted); `nil` is the primary `AppIcon`.
    var iconName: String? {
        switch self {
        case .buddy: nil
        case .backpack: "AppIconBackpack"
        case .letter: "AppIconLetter"
        case .scan: "AppIconScan"
        case .clock: "AppIconClock"
        }
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.buddy
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
        environment(\.theme, theme ?? .buddy)
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
