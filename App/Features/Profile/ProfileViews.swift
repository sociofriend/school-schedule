import PhotosUI
import SwiftUI

/// Round kid photo, or the first letter of the name on the theme color.
struct AvatarView: View {
    let photo: UIImage?
    let name: String
    var size: CGFloat = 56
    @Environment(\.theme) private var theme

    var body: some View {
        Group {
            if let photo {
                Image(uiImage: photo).resizable().scaledToFill()
            } else {
                ZStack {
                    Rectangle().fill(theme.accent.gradient)
                    if let letter = name.first {
                        Text(String(letter).uppercased()).font(.system(size: size * 0.45, weight: .heavy))
                    } else {
                        Image(systemName: "person.fill").font(.system(size: size * 0.42, weight: .bold))
                    }
                }
                .foregroundStyle(theme.onAccent)
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
    @State private var item: PhotosPickerItem?
    @Environment(\.theme) private var theme

    var body: some View {
        PhotosPicker(selection: $item, matching: .images) {
            AvatarView(photo: profile.photo, name: profile.name, size: size)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "camera.fill")
                        .font(.headline)
                        .foregroundStyle(theme.onAccent)
                        .frame(width: 40, height: 40)
                        .background(theme.accent, in: .circle)
                        .overlay(Circle().stroke(theme.background, lineWidth: 3))
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

/// Three theme cards; selection previews instantly.
struct ThemePicker: View {
    @Binding var selection: AppTheme

    var body: some View {
        HStack(spacing: 12) {
            ForEach(AppTheme.allCases) { theme in
                Button { withAnimation(.spring) { selection = theme } } label: {
                    VStack(spacing: 8) {
                        Image(systemName: theme.symbol)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(theme.accent)
                            .frame(maxWidth: .infinity, minHeight: 72)
                            .background(theme.background, in: .rect(cornerRadius: 18, style: .continuous))
                        Text(theme.name).font(.headline).fontDesign(theme.fontDesign)
                        Text(theme.tagline).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(selection == theme ? theme.accent : .clear, lineWidth: 3)
                    }
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel(theme.name)
                .accessibilityAddTraits(selection == theme ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// First launch: name, photo and theme.
struct OnboardingView: View {
    @Bindable var profile: ProfileViewModel
    @FocusState private var isNameFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Բարի գալուստ 👋").font(.largeTitle.bold()).padding(.top, 32)
                Text("Եկ ծանոթանանք").font(.title3).foregroundStyle(.secondary)
                AvatarPicker(profile: profile)
                TextField("Անունդ", text: $profile.name)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .textContentType(.givenName)
                    .submitLabel(.done)
                    .focused($isNameFocused)
                    .padding()
                    .background(profile.theme.surface, in: .rect(cornerRadius: 18, style: .continuous))
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ընտրիր քո ոճը").font(.title3.bold())
                    ThemePicker(selection: $profile.theme)
                }
                Button {
                    profile.finishOnboarding()
                } label: {
                    Text("Սկսել").font(.headline).frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .foregroundStyle(profile.theme.onAccent)
                .disabled(!profile.canFinish)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(profile.theme.background.ignoresSafeArea())
        .themed(profile.theme)
        .interactiveDismissDisabled()
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
