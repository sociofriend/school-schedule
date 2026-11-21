import PhotosUI
import SwiftUI

/// Round kid avatar: photo, character emoji, or a placeholder (initial on the theme color, or neutral gray).
struct AvatarView: View {
    let photo: UIImage?
    var emoji: String?
    let name: String
    var size: CGFloat = 56
    var neutral = false
    @Environment(\.theme) private var theme

    var body: some View {
        Group {
            if let photo {
                Image(uiImage: photo).resizable().scaledToFill()
            } else if let emoji {
                Text(emoji)
                    .font(.system(size: size * 0.56))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(rgb: 0xFFE9D6))
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

extension AvatarView {
    init(profile: ProfileViewModel, size: CGFloat = 56, neutral: Bool = false) {
        self.init(photo: profile.photo, emoji: profile.emoji, name: profile.name, size: size, neutral: neutral)
    }
}

/// Big avatar in a rainbow ring, then camera / library tiles and a grid of characters.
struct AvatarChooser: View {
    let profile: ProfileViewModel
    var avatarSize: CGFloat = 164
    @State private var item: PhotosPickerItem?
    @State private var isCameraPresented = false

    private static let ring = AngularGradient(colors: [.blue, .purple, .pink, .orange, .yellow, .cyan, .blue], center: .center)

    var body: some View {
        VStack(spacing: 22) {
            AvatarView(profile: profile, size: avatarSize, neutral: true)
                .padding(5)
                .background(Color(.systemBackground), in: .circle)
                .padding(6)
                .background(Self.ring, in: .circle)
                .contentTransition(.opacity)
                .animation(.spring(response: 0.35, dampingFraction: 0.6), value: profile.emoji)
                .sensoryFeedback(.impact(weight: .light), trigger: profile.emoji)

            HStack(spacing: 12) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    tile("Լուսանկարել", symbol: "camera.fill", tint: .blue) { isCameraPresented = true }
                }
                PhotosPicker(selection: $item, matching: .images) {
                    tileLabel("Պատկերասրահ", symbol: "photo.fill", tint: .green)
                }
                .buttonStyle(BouncyButtonStyle())
            }

            VStack(spacing: 12) {
                Text("կամ ընտրիր կերպար").font(.subheadline).foregroundStyle(.secondary)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                    ForEach(ProfileViewModel.characters, id: \.self) { character in
                        let isOn = profile.emoji == character
                        Button { profile.setEmoji(character) } label: {
                            Text(character)
                                .font(.system(size: 34))
                                .frame(width: 64, height: 64)
                                .background(Color(.secondarySystemGroupedBackground), in: .circle)
                                .overlay(Circle().strokeBorder(isOn ? Color.primary : .clear, lineWidth: 3))
                                .scaleEffect(isOn ? 1.08 : 1)
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityAddTraits(isOn ? .isSelected : [])
                    }
                }
            }
        }
        .onChange(of: item) {
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) { profile.setPhoto(data) }
                self.item = nil
            }
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraPicker { profile.setPhoto($0) }.ignoresSafeArea()
        }
    }

    private func tile(_ title: String, symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) { tileLabel(title, symbol: symbol, tint: tint) }
            .buttonStyle(BouncyButtonStyle())
    }

    private func tileLabel(_ title: String, symbol: String, tint: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol).font(.title2.bold()).foregroundStyle(tint)
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, minHeight: 84)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 22, style: .continuous))
    }
}

/// System camera (front-facing) for a selfie avatar.
struct CameraPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        if UIImagePickerController.isCameraDeviceAvailable(.front) { picker.cameraDevice = .front }
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImage(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

/// A miniature Today screen drawn in a theme: greeting, "now" card and lesson rows.
struct ThemeMiniScreen<Avatar: View>: View {
    let theme: AppTheme
    var greeting = "Բարև"
    var lessons: [String] = []
    @ViewBuilder var avatar: Avatar

    private var ink: Color { theme.colorScheme == .dark ? .white : Color(rgb: 0x2E2A4F) }
    private static var dots: [Color] { [.blue, .indigo, .pink] }
    private static var bars: [CGFloat] { [64, 48, 56] }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                avatar.frame(width: 18, height: 18)
                Text(greeting).font(.system(size: 14, weight: .heavy, design: theme.fontDesign)).fontWidth(theme.fontWidth)
                Spacer(minLength: 0)
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
                    if i < lessons.count {
                        Text(lessons[i]).font(.system(size: 10, weight: .medium, design: theme.fontDesign)).foregroundStyle(ink)
                    } else {
                        Capsule().fill(ink.opacity(0.22)).frame(width: Self.bars[i], height: 5)
                    }
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

/// Selectable theme card (Settings): mini screen plus name and tagline.
struct ThemePreviewCard: View {
    let theme: AppTheme
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ThemeMiniScreen(theme: theme) { Circle().fill(theme.accent.gradient) }
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
}

/// Swipeable row of theme previews (Settings).
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

/// Settings screen for the profile.
struct ProfileEditView: View {
    @Bindable var profile: ProfileViewModel

    var body: some View {
        Form {
            Section {
                AvatarChooser(profile: profile, avatarSize: 120)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
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
