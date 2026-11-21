import SwiftUI

/// Color + symbol per subject, so children recognise lessons at a glance (before reading).
/// Matches common subject names in Armenian, Russian and English; unknown subjects get a stable color.
struct SubjectStyle: Equatable {
    let color: Color
    let symbol: String

    /// School stage, so a symbol matches what the kid has learned (no `function` graph before algebra).
    enum Stage: CaseIterable {
        case primary, middle, high // 1–4, 5–9, 10–12

        init?(grade: Int?) {
            switch grade {
            case 1...4: self = .primary
            case 5...9: self = .middle
            case 10...12: self = .high
            default: return nil
            }
        }
    }

    /// `symbol` is used when no grade is set; `staged` overrides it per stage (primary, middle, high).
    private typealias Rule = (keys: [String], color: Color, symbol: String, staged: [String]?)

    /// Order matters: the first rule whose key the subject contains wins (algebra before math).
    private static let rules: [Rule] = [
        (["հանրահաշ", "algebra", "алгеб"], .blue, "function", ["x.squareroot", "x.squareroot", "function"]),
        (["երկրաչ", "geometr", "геометр"], .blue, "function", ["triangle", "triangle", "cube.transparent"]),
        (["մաթ", "math", "матем"], .blue, "function", ["textformat.123", "plus.forwardslash.minus", "function"]),
        (["գրականություն", "literat", "литер"], .orange, "book.fill", ["book.fill", "book.fill", "books.vertical.fill"]),
        (["հայոց լեզու", "մայրենի", "ընթերց", "reading", "чтени"], .orange, "book.fill",
         ["pencil.and.scribble", "text.book.closed.fill", "text.book.closed.fill"]),
        (["անգլ", "english", "англ"], .indigo, "globe.europe.africa.fill", ["abc", "globe.europe.africa.fill", "globe.europe.africa.fill"]),
        (["ռուս", "russian", "русск"], .red, "character.book.closed.fill", nil),
        (["ֆրանս", "գերման", "french", "german", "франц", "немец"], .purple, "character.bubble.fill", nil),
        (["ֆիզիկ", "physic", "физик"], Color(red: 0.0, green: 0.52, blue: 0.72), "atom", ["bolt.fill", "bolt.fill", "atom"]),
        (["քիմ", "chem", "хими"], Color(red: 0.0, green: 0.6, blue: 0.5), "flask.fill", nil),
        (["կենսաբ", "biolog", "биолог"], .green, "leaf.fill", ["leaf.fill", "leaf.fill", "microbe.fill"]),
        (["շրջակա", "բնություն", "բնագիտ", "science", "природ"], .green, "leaf.fill", ["tree.fill", "leaf.fill", "leaf.fill"]),
        (["աշխարհագր", "geograph", "географ"], .teal, "globe.americas.fill", ["map.fill", "map.fill", "globe.americas.fill"]),
        (["հայրենիք"], .brown, "flag.fill", nil),
        (["պատմ", "histor", "истор"], .brown, "building.columns.fill", ["crown.fill", "building.columns.fill", "scroll.fill"]),
        (["հասարակագ", "social", "обществ"], .indigo, "person.3.fill", nil),
        (["ֆիզկուլտ", "ֆիզ. դաստ", "ֆիզդաստ", "մարմն", "sport", "physical", "физкул"], .pink, "figure.run",
         ["figure.play", "figure.run", "figure.run"]),
        (["երաժշտ", "music", "музык"], .purple, "music.note", ["music.note", "music.note", "music.quarternote.3"]),
        (["կերպարվ", "նկար", "fine art", "drawing", "рисов", "изо"], Color(red: 0.85, green: 0.58, blue: 0.0), "paintpalette.fill",
         ["paintbrush.fill", "paintpalette.fill", "paintpalette.fill"]),
        (["ինֆորմատ", "համակարգչ", "comput", "informat", "информ"], .gray, "laptopcomputer",
         ["computermouse.fill", "laptopcomputer", "chevron.left.forwardslash.chevron.right"]),
        (["շախմատ", "chess", "шахмат"], .brown, "checkerboard.rectangle", nil),
        (["տեխնոլ", "աշխատանք", "techno", "технол", "труд"], .orange, "hammer.fill", ["scissors", "hammer.fill", "hammer.fill"]),
        (["զինվոր", "նզպ", "military", "нвп"], Color(red: 0.33, green: 0.45, blue: 0.2), "shield.fill", nil),
        (["առողջ", "health", "здоров"], .red, "heart.fill", nil),
    ]

    private static let fallbackColors: [Color] = [.blue, .orange, .green, .pink, .purple, .teal, .indigo, .red]

    /// Grade saved in the kid's profile (App Group), read by both the app and the widget.
    static var savedGrade: Int? { AppGroup.defaults.object(forKey: AppGroup.gradeKey) as? Int }

    init(color: Color, symbol: String) {
        self.color = color
        self.symbol = symbol
    }

    /// Color stays the same across grades (recognition); only the symbol follows the stage.
    init(subject: String, grade: Int? = SubjectStyle.savedGrade) {
        let key = subject.lowercased()
        if let rule = Self.rules.first(where: { rule in rule.keys.contains(where: key.contains) }) {
            let stage = Stage(grade: grade)
            let staged = zip(Stage.allCases, rule.staged ?? []).first { $0.0 == stage }?.1
            self.init(color: rule.color, symbol: staged ?? rule.symbol)
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
    @Environment(\.schoolGrade) private var environmentGrade

    var body: some View {
        let style = SubjectStyle(subject: subject, grade: environmentGrade ?? SubjectStyle.savedGrade)
        Image(systemName: style.symbol)
            .font(.system(size: size * 0.45, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(style.color.gradient, in: .rect(cornerRadius: size * 0.3, style: .continuous))
            .accessibilityHidden(true)
    }
}

private struct SchoolGradeKey: EnvironmentKey {
    static let defaultValue: Int? = nil
}

extension EnvironmentValues {
    /// The kid's grade, set at the app root so subject icons redraw as soon as it changes.
    var schoolGrade: Int? {
        get { self[SchoolGradeKey.self] }
        set { self[SchoolGradeKey.self] = newValue }
    }
}
