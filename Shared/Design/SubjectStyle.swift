import SwiftUI

/// Color + symbol per subject, so children recognise lessons at a glance (before reading).
/// Matches common subject names in Armenian, Russian and English; unknown subjects get a stable color.
struct SubjectStyle: Equatable {
    let color: Color
    let symbol: String

    private static let rules: [(keys: [String], color: Color, symbol: String)] = [
        (["մաթ", "հանրահաշ", "երկրաչ", "math", "алгеб", "геометр", "матем"], .blue, "function"),
        (["հայոց լեզու", "մայրենի", "գրականություն", "ընթերց", "literat", "reading", "литер", "чтени"], .orange, "book.fill"),
        (["անգլ", "english", "англ"], .indigo, "globe.europe.africa.fill"),
        (["ռուս", "russian", "русск"], .red, "character.book.closed.fill"),
        (["ֆրանս", "գերման", "french", "german", "франц", "немец"], .purple, "character.bubble.fill"),
        (["ֆիզիկ", "physic", "физик"], .cyan, "atom"),
        (["քիմ", "chem", "хими"], .mint, "flask.fill"),
        (["կենսաբ", "բնագիտ", "biolog", "science", "биолог", "природ"], .green, "leaf.fill"),
        (["աշխարհագր", "geograph", "географ"], .teal, "globe.americas.fill"),
        (["պատմ", "histor", "истор"], .brown, "building.columns.fill"),
        (["ֆիզկուլտ", "ֆիզ. դաստ", "ֆիզդաստ", "մարմն", "sport", "physical", "физкул"], .pink, "figure.run"),
        (["երաժշտ", "music", "музык"], .purple, "music.note"),
        (["կերպարվ", "նկար", "fine art", "drawing", "рисов", "изо"], .yellow, "paintpalette.fill"),
        (["ինֆորմատ", "համակարգչ", "comput", "informat", "информ"], .gray, "laptopcomputer"),
        (["շախմատ", "chess", "шахмат"], .brown, "checkerboard.rectangle"),
        (["տեխնոլ", "աշխատանք", "techno", "технол", "труд"], .orange, "hammer.fill"),
    ]

    private static let fallbackColors: [Color] = [.blue, .orange, .green, .pink, .purple, .teal, .indigo, .red]

    init(color: Color, symbol: String) {
        self.color = color
        self.symbol = symbol
    }

    init(subject: String) {
        let key = subject.lowercased()
        if let rule = Self.rules.first(where: { rule in rule.keys.contains(where: key.contains) }) {
            self.init(color: rule.color, symbol: rule.symbol)
        } else {
            // Stable across launches (String.hashValue is randomised per process).
            let sum = key.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
            self.init(color: Self.fallbackColors[sum % Self.fallbackColors.count], symbol: "book.closed.fill")
        }
    }
}

/// Rounded, colored subject badge reused by the app and the widget.
struct SubjectIcon: View {
    let subject: String
    var size: CGFloat = 40

    var body: some View {
        let style = SubjectStyle(subject: subject)
        Image(systemName: style.symbol)
            .font(.system(size: size * 0.45, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(style.color.gradient, in: .rect(cornerRadius: size * 0.3, style: .continuous))
            .accessibilityHidden(true)
    }
}
