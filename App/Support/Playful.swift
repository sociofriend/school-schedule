import SwiftUI

/// Friendly greeting by time of day.
enum Greeting {
    static func text(for date: Date = .now, calendar: Calendar = .current) -> (title: String, emoji: String) {
        switch calendar.component(.hour, from: date) {
        case 5..<12: ("Բարի առավոտ", "☀️")
        case 12..<18: ("Բարի օր", "🌤️")
        case 18..<23: ("Բարի երեկո", "🌙")
        default: ("Բարի գիշեր", "✨")
        }
    }

    /// Short encouragement for the checklist, based on progress.
    static func cheer(done: Int, total: Int) -> String {
        guard total > 0 else { return "Անելիքներ չկան. հանգստացիր 🎈" }
        switch Double(done) / Double(total) {
        case 1: return "Ամեն ինչ արված է։ Դու հրաշալի ես 🏆"
        case 0.5...: return "Կեսից ավելին արված է, շարունակիր 💪"
        case 0.01...: return "Լավ սկիզբ է 🚀"
        default: return "Սկսենք 🌱"
        }
    }
}

/// Animated circular progress.
struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 10
    var tint: Color = .green

    var body: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(progress > 0 ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
        }
        .accessibilityElement()
        .accessibilityLabel("Առաջընթաց")
        .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
    }
}

/// Soft colored card container.
struct CardBackground: ViewModifier {
    var tint: Color = .accentColor

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(tint.opacity(0.12), in: .rect(cornerRadius: 22, style: .continuous))
    }
}

extension View {
    func card(tint: Color = .accentColor) -> some View { modifier(CardBackground(tint: tint)) }
}

/// Squishy press feedback for big kid-friendly buttons.
struct BouncyButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.theme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? (theme.isPlayful ? 0.94 : 0.98) : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// One-shot confetti burst. Skipped when Reduce Motion is on or the theme is a calm (teen) one.
struct ConfettiView: View {
    let trigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.theme) private var theme
    @State private var start: Date?

    private static let colors: [Color] = [.pink, .orange, .yellow, .green, .blue, .purple]
    private static let duration: TimeInterval = 2.2

    var body: some View {
        TimelineView(.animation(paused: start == nil)) { timeline in
            Canvas { context, size in
                guard let start else { return }
                let t = timeline.date.timeIntervalSince(start)
                guard t < Self.duration else { return }
                for i in 0..<70 {
                    let seed = Double(i)
                    let x = size.width * (0.5 + 0.45 * sin(seed * 12.9898))
                    let speed = 260 + 140 * abs(sin(seed * 4.1))
                    let y = -20 + speed * t + 0.5 * 300 * t * t * 0.3
                    let wobble = 18 * sin(t * 6 + seed)
                    let rect = CGRect(x: x + wobble, y: y, width: 8, height: 12)
                    var piece = context
                    piece.opacity = 1 - t / Self.duration
                    piece.translateBy(x: rect.midX, y: rect.midY)
                    piece.rotate(by: .radians(t * 4 + seed))
                    piece.fill(Path(roundedRect: CGRect(x: -4, y: -6, width: 8, height: 12), cornerRadius: 2),
                               with: .color(Self.colors[i % Self.colors.count]))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) {
            guard !reduceMotion, theme.isPlayful else { return }
            start = .now
            Task {
                try? await Task.sleep(for: .seconds(Self.duration))
                start = nil
            }
        }
    }
}
