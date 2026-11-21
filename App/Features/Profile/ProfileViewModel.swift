import Observation
import UIKit

/// The kid's name, photo and theme; also switches the app icon to match the theme.
@MainActor
@Observable
final class ProfileViewModel {
    var name: String { didSet { store.name = name.trimmingCharacters(in: .whitespacesAndNewlines) } }
    var theme: AppTheme { didSet { store.theme = theme } }
    private(set) var photo: UIImage?
    private(set) var isComplete: Bool

    @ObservationIgnored private let store: ProfileStore

    init(store: ProfileStore = ProfileStore()) {
        self.store = store
        name = store.name
        theme = store.theme
        isComplete = store.isComplete
        photo = store.photoData.flatMap { ImageTools.thumbnail(from: $0, maxPixelSize: 600) }
    }

    var canFinish: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    /// First word of the name, for greetings.
    var firstName: String { name.split(separator: " ").first.map(String.init) ?? "" }

    func setPhoto(_ data: Data) {
        guard let image = UIImage(data: data) else { return }
        let resized = ImageTools.resized(image, maxDimension: 600)
        store.photoData = resized.jpegData(compressionQuality: 0.85)
        photo = resized
    }

    func removePhoto() {
        store.photoData = nil
        photo = nil
    }

    func finishOnboarding() {
        guard canFinish else { return }
        store.isComplete = true
        isComplete = true
        applyIcon()
    }

    /// Matches the home-screen icon to the theme (iOS shows a short confirmation alert).
    func applyIcon() {
        let app = UIApplication.shared
        guard app.supportsAlternateIcons, app.alternateIconName != theme.iconName else { return }
        app.setAlternateIconName(theme.iconName)
    }
}
