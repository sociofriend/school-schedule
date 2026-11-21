import Foundation

/// The kid's profile in the App Group: name, theme, onboarding flag; the photo is a JPEG file.
struct ProfileStore {
    var defaults: UserDefaults = AppGroup.defaults
    var fileManager: FileManager = .default

    private static let nameKey = "profile.name"
    private static let themeKey = "profile.theme"
    private static let completeKey = "profile.complete"
    private static let emojiKey = "profile.emoji"

    var name: String {
        get { defaults.string(forKey: Self.nameKey) ?? "" }
        nonmutating set { defaults.set(newValue, forKey: Self.nameKey) }
    }

    var theme: AppTheme {
        get { defaults.string(forKey: Self.themeKey).flatMap(AppTheme.init(rawValue:)) ?? .apricot }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Self.themeKey) }
    }

    /// Character avatar (an animal emoji) used instead of a photo.
    var emoji: String? {
        get { defaults.string(forKey: Self.emojiKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.emojiKey) }
    }

    var isComplete: Bool {
        get { defaults.bool(forKey: Self.completeKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.completeKey) }
    }

    var photoData: Data? {
        get { photoURL.flatMap { try? Data(contentsOf: $0) } }
        nonmutating set {
            guard let url = photoURL else { return }
            if let newValue { try? newValue.write(to: url, options: .atomic) } else { try? fileManager.removeItem(at: url) }
        }
    }

    private var photoURL: URL? {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier)?
            .appendingPathComponent("profile-photo.jpg")
    }
}
