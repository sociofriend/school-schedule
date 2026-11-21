import SwiftUI

/// Each theme's set of small animations, used across the app through the `themed…` modifiers below.
/// All are off with Reduce Motion; teen themes move less and idle more rarely.
struct ThemeMotion {
    enum Effect { case bounce, pulse, variableColor, wiggle, breathe, rotate }

    /// Symbol reaction when something gets done (packed item, picked theme).
    let done: Effect
    /// Rare repeating touch on a live symbol (Now card, streak flame); iOS 18 only, to stay battery-light.
    let idle: Effect
    /// Seconds between idle plays.
    let idleDelay: Double
    /// Success pop (task tick, progress ring, packed backpack): peak scale and wobble in degrees.
    let popScale: CGFloat
    let popAngle: Double
    /// Empty-state illustration drift, in points.
    let floatTravel: CGFloat
    /// Card entrance rise, in points.
    let rise: CGFloat
    /// Spring for entrances.
    let spring: Animation
}

extension AppTheme {
    var motion: ThemeMotion {
        let playful = Animation.spring(response: 0.45, dampingFraction: 0.68)
        let calm = Animation.smooth(duration: 0.35)
        return switch self {
        // Kids: a smiley hop, a jostled backpack, a stamped letter, a scanner sweep, a ringing alarm.
        case .buddy: ThemeMotion(done: .bounce, idle: .wiggle, idleDelay: 6, popScale: 1.35, popAngle: 10, floatTravel: 8, rise: 14, spring: playful)
        case .backpack: ThemeMotion(done: .wiggle, idle: .wiggle, idleDelay: 7, popScale: 1.3, popAngle: -12, floatTravel: 6, rise: 12, spring: playful)
        case .letter: ThemeMotion(done: .bounce, idle: .breathe, idleDelay: 6, popScale: 1.28, popAngle: 0, floatTravel: 6, rise: 12, spring: playful)
        case .scan: ThemeMotion(done: .variableColor, idle: .variableColor, idleDelay: 5, popScale: 1.22, popAngle: 0, floatTravel: 5, rise: 10, spring: playful)
        case .clock: ThemeMotion(done: .wiggle, idle: .wiggle, idleDelay: 8, popScale: 1.25, popAngle: 16, floatTravel: 6, rise: 12, spring: playful)
        // Teens: short, quiet and rare.
        case .graphite: ThemeMotion(done: .pulse, idle: .pulse, idleDelay: 12, popScale: 1.08, popAngle: 0, floatTravel: 2, rise: 4, spring: calm)
        case .midnight: ThemeMotion(done: .variableColor, idle: .variableColor, idleDelay: 10, popScale: 1.08, popAngle: 0, floatTravel: 3, rise: 4, spring: calm)
        case .neon: ThemeMotion(done: .pulse, idle: .breathe, idleDelay: 9, popScale: 1.12, popAngle: 0, floatTravel: 3, rise: 6, spring: calm)
        case .sand: ThemeMotion(done: .pulse, idle: .breathe, idleDelay: 14, popScale: 1.06, popAngle: 0, floatTravel: 2, rise: 3, spring: calm)
        case .emerald: ThemeMotion(done: .bounce, idle: .pulse, idleDelay: 12, popScale: 1.1, popAngle: 0, floatTravel: 3, rise: 4, spring: calm)
        }
    }
}

extension View {
    /// Plays the theme's "done" symbol effect when `value` changes (SF Symbol images).
    func themedDoneEffect<V: Equatable>(value: V) -> some View { modifier(DoneEffect(value: value)) }

    /// Repeats the theme's idle symbol effect every few seconds while `isActive` (iOS 18+).
    func themedIdle(isActive: Bool = true) -> some View { modifier(IdleEffect(isActive: isActive)) }

    /// A short pop (scale, and a wobble in kid themes) when `trigger` changes.
    func themedPop<V: Equatable>(trigger: V) -> some View { modifier(Pop(trigger: trigger)) }

    /// Slow up-and-down drift for empty-state illustrations.
    func themedFloat() -> some View { modifier(Drift()) }

    /// Fades and rises in on first appearance; `order` staggers siblings.
    func themedRise(order: Int = 0) -> some View { modifier(Rise(order: order)) }
}

private struct DoneEffect<V: Equatable>: ViewModifier {
    let value: V
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            switch theme.motion.done {
            case .bounce, .breathe, .rotate: content.symbolEffect(.bounce, value: value)
            case .pulse: content.symbolEffect(.pulse, value: value)
            case .variableColor: content.symbolEffect(.variableColor.iterative, value: value)
            case .wiggle:
                if #available(iOS 18, *) {
                    content.symbolEffect(.wiggle, value: value)
                } else {
                    content.symbolEffect(.bounce, value: value)
                }
            }
        }
    }
}

private struct IdleEffect: ViewModifier {
    let isActive: Bool
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else if #available(iOS 18, *) {
            idle(content)
        } else {
            content
        }
    }

    @available(iOS 18, *)
    @ViewBuilder private func idle(_ content: Content) -> some View {
        let options = SymbolEffectOptions.repeat(.periodic(delay: theme.motion.idleDelay))
        switch theme.motion.idle {
        case .bounce, .wiggle: content.symbolEffect(.wiggle, options: options, isActive: isActive)
        case .pulse: content.symbolEffect(.pulse, options: options, isActive: isActive)
        case .variableColor: content.symbolEffect(.variableColor.iterative, options: options, isActive: isActive)
        case .breathe: content.symbolEffect(.breathe, options: options, isActive: isActive)
        case .rotate: content.symbolEffect(.rotate, options: options, isActive: isActive)
        }
    }
}

private struct PopValues {
    var scale: CGFloat = 1
    var angle: Double = 0
}

private struct Pop<V: Equatable>: ViewModifier {
    let trigger: V
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            let motion = theme.motion
            content.keyframeAnimator(initialValue: PopValues(), trigger: trigger) { view, value in
                view.scaleEffect(value.scale).rotationEffect(.degrees(value.angle))
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    SpringKeyframe(motion.popScale, duration: 0.16)
                    SpringKeyframe(1, duration: 0.34, spring: .bouncy)
                }
                KeyframeTrack(\.angle) {
                    CubicKeyframe(motion.popAngle, duration: 0.1)
                    CubicKeyframe(-motion.popAngle * 0.6, duration: 0.12)
                    CubicKeyframe(0, duration: 0.14)
                }
            }
        }
    }
}

private struct Drift: ViewModifier {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            let travel = theme.motion.floatTravel
            content.phaseAnimator([false, true]) { view, up in
                view.offset(y: up ? -travel : 0)
            } animation: { _ in
                .easeInOut(duration: 1.8)
            }
        }
    }
}

private struct Rise: ViewModifier {
    let order: Int
    @State private var isShown = false
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isShown ? 1 : 0)
            .offset(y: isShown || reduceMotion ? 0 : theme.motion.rise)
            .onAppear {
                guard !isShown else { return }
                withAnimation(theme.motion.spring.delay(Double(order) * 0.05)) { isShown = true }
            }
    }
}

// MARK: - Ambient motion

/// Always-on gentle motion for decorative emoji and icons (sun spins, balloon bobs, star twinkles…).
/// Kid themes move clearly; teen themes at about a third; Reduce Motion keeps everything still.
enum Ambient {
    case spin, bob, sway, pulse, twinkle

    /// The motion that suits an emoji.
    init(emoji: String) {
        switch emoji {
        case "☀️": self = .spin
        case "✨", "⭐️", "🌟": self = .twinkle
        case "🌙", "🏆", "🌱", "🎒", "🎉", "🍎", "👋", "🎁": self = .sway
        case "💪", "🔥", "✅", "👏": self = .pulse
        default: self = .bob
        }
    }
}

extension View {
    /// Loops a small decorative motion; use on emoji and SF Symbols, not on text or controls.
    func ambient(_ kind: Ambient) -> some View { modifier(AmbientMotion(kind: kind)) }
}

private struct AmbientMotion: ViewModifier {
    let kind: Ambient
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            let k: CGFloat = theme.isPlayful ? 1 : 0.35
            let pace: Double = theme.isPlayful ? 1 : 1.6
            switch kind {
            case .spin:
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                    let period = 12 * pace
                    let turn = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
                    content.rotationEffect(.degrees(turn * 360))
                }
            case .bob:
                content.phaseAnimator([false, true]) { view, up in
                    view.offset(y: up ? -5 * k : 1)
                } animation: { _ in .easeInOut(duration: 1.3 * pace) }
            case .sway:
                content.phaseAnimator([false, true]) { view, right in
                    view.rotationEffect(.degrees(right ? 12 * k : -12 * k), anchor: .bottom)
                } animation: { _ in .easeInOut(duration: 1.1 * pace) }
            case .pulse:
                content.phaseAnimator([false, true]) { view, big in
                    view.scaleEffect(big ? 1 + 0.15 * k : 1)
                } animation: { _ in .easeInOut(duration: 0.8 * pace) }
            case .twinkle:
                content.phaseAnimator([false, true]) { view, lit in
                    view.scaleEffect(lit ? 1 + 0.2 * k : 1 - 0.06 * k)
                        .rotationEffect(.degrees(lit ? 14 * k : -8 * k))
                } animation: { _ in .easeInOut(duration: 1.0 * pace) }
            }
        }
    }
}

/// Text whose trailing emoji keeps a small theme motion, e.g. "Լավ սկիզբ է 🚀".
struct EmojiText: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        let (head, emoji) = Self.split(text)
        if let emoji {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(head)
                Text(emoji).ambient(Ambient(emoji: emoji))
            }
            .accessibilityElement(children: .combine)
        } else {
            Text(text)
        }
    }

    /// Splits off a trailing emoji (pictographs only, so digits and punctuation stay).
    static func split(_ text: String) -> (String, String?) {
        guard let last = text.last,
              let scalar = last.unicodeScalars.first,
              scalar.properties.isEmoji, scalar.value >= 0x2600 else { return (text, nil) }
        return (String(text.dropLast()).trimmingCharacters(in: .whitespaces), String(last))
    }
}
