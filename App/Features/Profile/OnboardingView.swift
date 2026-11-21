import SwiftUI

/// First launch, one question per screen: hello → name → photo or character → style.
/// Neutral system colors until the style step, which turns the whole screen into the picked theme
/// (in light or dark, following the system or the kid's choice).
struct OnboardingView: View {
    @Bindable var profile: ProfileViewModel
    @State private var step = Step.hello
    @State private var celebrations = 0
    @FocusState private var isNameFocused: Bool

    enum Step: Int, CaseIterable { case hello, name, avatar, style }

    private var isStyle: Bool { step == .style }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            VStack(spacing: 0) {
                if step != .hello { topBar }
                page
                    .id(step)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)))
                    .frame(maxHeight: .infinity, alignment: .top)
                footer
            }
            ConfettiView(trigger: celebrations).ignoresSafeArea()
        }
        .preferredColorScheme(profile.appearance.colorScheme)
        .fontDesign(isStyle ? profile.theme.fontDesign : .rounded)
        .animation(.smooth(duration: 0.45), value: profile.theme)
        .animation(.smooth(duration: 0.45), value: profile.appearance)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: step)
        .sensoryFeedback(.selection, trigger: profile.theme)
        .interactiveDismissDisabled()
    }

    // MARK: Chrome

    @ViewBuilder private var background: some View {
        if isStyle {
            profile.theme.background
        } else {
            RadialGradient(colors: [Color(.systemBackground), Color(.systemGroupedBackground)],
                           center: .init(x: 0.5, y: 0.3), startRadius: 0, endRadius: 520)
        }
    }

    private var topBar: some View {
        HStack {
            Button("Հետ", systemImage: "chevron.left", action: back)
                .labelStyle(.iconOnly)
                .font(.headline)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: .circle)
            Spacer()
            HStack(spacing: 6) {
                ForEach(1..<Step.allCases.count, id: \.self) { i in
                    Capsule()
                        .fill(Color.primary.opacity(i <= step.rawValue ? 1 : 0.15))
                        .frame(width: i == step.rawValue ? 28 : 8, height: 8)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Քայլ \(step.rawValue)՝ \(Step.allCases.count - 1)-ից")
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .foregroundStyle(.primary)
    }

    private var footer: some View {
        Button(action: next) {
            Text(primaryTitle)
                .font(.headline)
                .foregroundStyle(isStyle ? profile.theme.onAccent : Color(.systemBackground))
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(isStyle ? profile.theme.accent : Color.primary, in: .capsule)
                .contentTransition(.opacity)
        }
        .buttonStyle(BouncyButtonStyle())
        .opacity(canContinue ? 1 : 0.3)
        .disabled(!canContinue)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private var primaryTitle: String {
        switch step {
        case .hello: "Սկսենք"
        case .name: "Շարունակել"
        case .avatar: profile.hasAvatar ? "Շարունակել" : "Հետո"
        case .style: "Պատրաստ է 🎉"
        }
    }

    private var canContinue: Bool { step != .name || profile.canFinish }

    // MARK: Pages

    @ViewBuilder private var page: some View {
        switch step {
        case .hello: hello
        case .name: namePage
        case .avatar: avatarPage
        case .style: stylePage
        }
    }

    private var hello: some View {
        VStack(spacing: 36) {
            Spacer(minLength: 24)
            SubjectOrbit().frame(width: 300, height: 300)
            VStack(spacing: 10) {
                Text("Դասացուցակ").font(.system(size: 40, weight: .heavy))
                Text("Դասերը, տնայինները և պայուսակը՝ մի տեղում")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            Spacer(minLength: 0)
        }
    }

    private var namePage: some View {
        VStack(spacing: 28) {
            title("Ինչպե՞ս է\nքո անունը")
            VStack(spacing: 10) {
                TextField("Անուն", text: $profile.name)
                    .font(.system(size: 48, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .textContentType(.givenName)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($isNameFocused)
                    .onSubmit(next)
                Capsule().fill(Color.primary).frame(width: 220, height: 4)
            }
            .padding(.horizontal, 24)
            Text(profile.firstName.isEmpty ? " " : "Բարև, \(profile.firstName) 👋")
                .font(.title3)
                .foregroundStyle(.secondary)
                .contentTransition(.interpolate)
                .animation(.snappy, value: profile.firstName)
        }
        .onAppear { isNameFocused = true }
    }

    private var avatarPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                title("Ընտրիր քո\nնկարը")
                AvatarChooser(profile: profile).padding(.horizontal, 24)
            }
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }

    private var stylePage: some View {
        VStack(spacing: 26) {
            VStack(spacing: 8) {
                title("Ընտրիր քո ոճը")
                Text("Տես, թե ինչպես կերևա").font(.title3).foregroundStyle(.secondary)
            }
            ThemeMiniScreen(theme: profile.theme,
                            greeting: "Բարև, \(profile.firstName)",
                            lessons: ["Հայոց լեզու", "Անգլերեն", "Երաժշտություն"]) {
                AvatarView(profile: profile, size: 18)
            }
            .scaleEffect(1.55)
            .frame(width: 156 * 1.55, height: 196 * 1.55)
            .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(AppTheme.allCases) { theme in
                        ThemeSwatch(theme: theme, isSelected: profile.theme == theme) { profile.theme = theme }
                    }
                }
                .padding(.vertical, 8)
            }
            .contentMargins(.horizontal, 24, for: .scrollContent)
            .scrollIndicators(.hidden)
            AppearancePicker(selection: $profile.appearance)
                .padding(.horizontal, 40)
        }
    }

    private func title(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 34, weight: .heavy))
            .multilineTextAlignment(.center)
            .padding(.top, 28)
            .padding(.horizontal, 24)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: Navigation

    private func next() {
        guard canContinue else { return }
        isNameFocused = false
        if let following = Step(rawValue: step.rawValue + 1) {
            step = following
        } else {
            celebrations += 1
            Task {
                try? await Task.sleep(for: .seconds(1.1))
                profile.finishOnboarding()
            }
        }
    }

    private func back() {
        isNameFocused = false
        step = Step(rawValue: step.rawValue - 1) ?? .hello
    }
}

/// Theme button: its app logo, name underneath.
private struct ThemeSwatch: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ThemeLogo(theme: theme, size: 70)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(isSelected ? Color.primary : .clear, lineWidth: 3))
                    .scaleEffect(isSelected ? 1.08 : 1)
                Text(theme.name).font(.subheadline.bold()).fontDesign(theme.fontDesign)
            }
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("\(theme.name), \(theme.tagline)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Hello hero: the app mark with subject bubbles slowly orbiting it (still when Reduce Motion is on).
private struct SubjectOrbit: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let bubbles: [(symbol: String, color: Color)] = [
        ("function", .blue), ("book.fill", .orange), ("globe.europe.africa.fill", .indigo),
        ("atom", .cyan), ("music.note", .purple), ("paintpalette.fill", .yellow), ("figure.run", .pink),
    ]

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let turn = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate / 40
            GeometryReader { proxy in
                let size = proxy.size
                let radius = min(size.width, size.height) / 2 - 30
                ZStack {
                    Circle()
                        .strokeBorder(Color.primary.opacity(0.1), style: StrokeStyle(lineWidth: 2, dash: [5, 7]))
                        .padding(26)
                    ForEach(Self.bubbles.indices, id: \.self) { i in
                        let angle = (Double(i) / Double(Self.bubbles.count) + turn) * 2 * .pi
                        Image(systemName: Self.bubbles[i].symbol)
                            .font(.system(size: 21, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(Self.bubbles[i].color.gradient, in: .circle)
                            .shadow(color: Self.bubbles[i].color.opacity(0.35), radius: 8, y: 4)
                            .position(x: size.width / 2 + radius * cos(angle), y: size.height / 2 + radius * sin(angle))
                    }
                    Image(systemName: "calendar")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 120, height: 120)
                        .background(Color(.systemBackground), in: .rect(cornerRadius: 34, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 20, y: 10)
                }
            }
        }
        .accessibilityHidden(true)
    }
}
