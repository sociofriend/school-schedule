import PhotosUI
import SwiftUI

/// Round kid photo, or a placeholder (first letter on the theme color, or neutral gray).
struct AvatarView: View {
    let photo: UIImage?
    let name: String
    var size: CGFloat = 56
    var neutral = false
    @Environment(\.theme) private var theme

    var body: some View {
        Group {
            if let photo {
                Image(uiImage: photo).resizable().scaledToFill()
            } else {
                ZStack {
                    Rectangle().fill(neutral ? AnyShapeStyle(Color(.systemGray5)) : AnyShapeStyle(theme.accent.gradient))
                    if let letter = name.first {
                        Text(String(letter).uppercased()).font(.system(size: size * 0.45, weight: .heavy))
                    } else {
                        Image(systemName: "person.fill").font(.system(size: size * 0.42, weight: .bold))
                    }
                }
                .foregroundStyle(neutral ? Color(.systemGray) : theme.onAccent)
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .accessibilityHidden(true)
    }
}

/// Photo button: tap to pick from the library; long-press to remove.
struct AvatarPicker: View {
    let profile: ProfileViewModel
    var size: CGFloat = 132
    var neutral = false
    @State private var item: PhotosPickerItem?
    @Environment(\.theme) private var theme

    var body: some View {
        PhotosPicker(selection: $item, matching: .images) {
            AvatarView(photo: profile.photo, name: profile.name, size: size, neutral: neutral)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "camera.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(neutral ? Color(.systemBackground) : theme.onAccent)
                        .frame(width: size * 0.3, height: size * 0.3)
                        .background(neutral ? Color.primary : theme.accent, in: .circle)
                        .overlay(Circle().stroke(Color(.systemGroupedBackground), lineWidth: 4))
                }
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityLabel("Ընտրել նկար")
        .contextMenu {
            if profile.photo != nil {
                Button("Հեռացնել նկարը", systemImage: "trash", role: .destructive, action: profile.removePhoto)
            }
        }
        .onChange(of: item) {
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) { profile.setPhoto(data) }
                self.item = nil
            }
        }
    }
}

/// A miniature Today screen drawn in a theme, so kids pick a style by seeing it.
struct ThemePreviewCard: View {
    let theme: AppTheme
    let isSelected: Bool

    private var ink: Color { theme.colorScheme == .dark ? .white : Color(rgb: 0x2E2A4F) }
    private static let dots: [Color] = [.blue, .indigo, .pink]
    private static let bars: [CGFloat] = [64, 48, 56]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            screen
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.name).font(.headline).fontDesign(theme.fontDesign).fontWidth(theme.fontWidth)
                    Text(theme.tagline).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.primary : Color(.tertiaryLabel))
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(.horizontal, 4)
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(isSelected ? Color.primary : .clear, lineWidth: 2.5)
        }
        .scaleEffect(isSelected ? 1 : 0.96)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }

    private var screen: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Circle().fill(theme.accent.gradient).frame(width: 18, height: 18)
                Text("Բարև").font(.system(size: 14, weight: .heavy, design: theme.fontDesign)).fontWidth(theme.fontWidth)
                Spacer()
                Image(systemName: theme.symbol).font(.system(size: 12, weight: .bold)).foregroundStyle(theme.accent)
            }
            .foregroundStyle(ink)
            VStack(alignment: .leading, spacing: 2) {
                Text("Հիմա").font(.system(size: 9, weight: .semibold)).opacity(0.85)
                Text("Մաթեմատիկա").font(.system(size: 14, weight: .heavy, design: theme.fontDesign)).fontWidth(theme.fontWidth)
                Capsule().fill(theme.onAccent.opacity(0.3)).frame(height: 4)
                    .overlay(alignment: .leading) { Capsule().fill(theme.onAccent).frame(width: 60, height: 4) }
                    .padding(.top, 4)
            }
            .foregroundStyle(theme.onAccent)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.accent.gradient, in: .rect(cornerRadius: 12, style: .continuous))
            ForEach(0..<3, id: \.self) { i in
                HStack(spacing: 6) {
                    Circle().fill(Self.dots[i]).frame(width: 7, height: 7)
                    Capsule().fill(ink.opacity(0.22)).frame(width: Self.bars[i], height: 5)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(theme.surface, in: .rect(cornerRadius: 8, style: .continuous))
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(12)
        .frame(width: 156, height: 196, alignment: .top)
        .background(theme.background, in: .rect(cornerRadius: 20, style: .continuous))
        .environment(\.colorScheme, theme.colorScheme)
        .accessibilityHidden(true)
    }
}

/// Swipeable row of theme previews.
struct ThemePicker: View {
    @Binding var selection: AppTheme

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(AppTheme.allCases) { theme in
                    Button { selection = theme } label: {
                        ThemePreviewCard(theme: theme, isSelected: selection == theme)
                    }
                    .buttonStyle(BouncyButtonStyle())
                    .accessibilityLabel("\(theme.name), \(theme.tagline)")
                    .accessibilityAddTraits(selection == theme ? .isSelected : [])
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// First launch, kept neutral (no theme yet): 1) name and photo, 2) style.
struct OnboardingView: View {
    @Bindable var profile: ProfileViewModel
    @State private var step = 0
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(0..<2, id: \.self) { i in
                    Capsule().fill(Color.primary.opacity(i <= step ? 1 : 0.12)).frame(height: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .accessibilityHidden(true)

            Group {
                if step == 0 { aboutYou } else { style }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)))

            footer
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .tint(.primary)
        .fontDesign(.rounded)
        .interactiveDismissDisabled()
    }

    private var aboutYou: some View {
        ScrollView {
            VStack(spacing: 32) {
                header("Բարև 👋", "Ինչպե՞ս քեզ կոչել")
                AvatarPicker(profile: profile, size: 140, neutral: true)
                TextField("Անունդ", text: $profile.name)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .textContentType(.givenName)
                    .submitLabel(.next)
                    .focused($isNameFocused)
                    .onSubmit(next)
                    .padding(.vertical, 16)
                    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal, 24)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var style: some View {
        VStack(spacing: 28) {
            header("Ընտրիր քո ոճը", "Հետո կարող ես փոխել Կարգավորումներում")
            ThemePicker(selection: $profile.theme)
        }
    }

    private func header(_ title: String, _ subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title).font(.largeTitle.bold())
            Text(subtitle).font(.title3).foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.top, 40)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button("Հետ", systemImage: "chevron.left") { withAnimation(.spring) { step = 0 } }
                    .labelStyle(.iconOnly)
                    .font(.headline)
                    .frame(width: 54, height: 54)
                    .background(Color(.secondarySystemGroupedBackground), in: .circle)
                    .transition(.scale.combined(with: .opacity))
            }
            Button(action: next) {
                Text(step == 0 ? "Շարունակել" : "Սկսել")
                    .font(.headline)
                    .foregroundStyle(Color(.systemBackground))
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(Color.primary, in: .capsule)
            }
            .opacity(profile.canFinish ? 1 : 0.3)
            .disabled(!profile.canFinish)
        }
        .buttonStyle(BouncyButtonStyle())
        .padding(24)
    }

    private func next() {
        guard profile.canFinish else { return }
        if step == 0 {
            isNameFocused = false
            withAnimation(.spring) { step = 1 }
        } else {
            profile.finishOnboarding()
        }
    }
}

/// Settings screen for the profile.
struct ProfileEditView: View {
    @Bindable var profile: ProfileViewModel

    var body: some View {
        Form {
            Section {
                AvatarPicker(profile: profile, size: 110).frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)
            Section("Անուն") {
                TextField("Անունդ", text: $profile.name).textContentType(.givenName)
            }
            if profile.photo != nil {
                Section {
                    Button("Հեռացնել նկարը", systemImage: "trash", role: .destructive, action: profile.removePhoto)
                }
            }
        }
        .navigationTitle("Իմ պրոֆիլը")
    }
}
