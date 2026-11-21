import Foundation

/// The kid's profile in the App Group: name, grade, theme, onboarding flag; the photo is a JPEG file.
struct ProfileStore {
    var defaults: UserDefaults = AppGroup.defaults
    var fileManager: FileManager = .default

    private static let nameKey = "profile.name"
    private static let themeKey = "profile.theme"
    private static let completeKey = "profile.complete"
    private static let emojiKey = "profile.emoji"
    private static let appearanceKey = "profile.appearance"
    private static let gradeKey = "profile.grade"

    var name: String {
        get { defaults.string(forKey: Self.nameKey) ?? "" }
        nonmutating set { defaults.set(newValue, forKey: Self.nameKey) }
    }

    /// School grade 1...12; `nil` until the kid picks one (also for profiles saved before grades existed).
    var grade: Int? {
        get { (defaults.object(forKey: Self.gradeKey) as? Int).flatMap { ArmenianCurriculum.grades.contains($0) ? $0 : nil } }
        nonmutating set { defaults.set(newValue, forKey: Self.gradeKey) }
    }

    var theme: AppTheme {
        get { defaults.string(forKey: Self.themeKey).flatMap(AppTheme.init(stored:)) ?? .buddy }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Self.themeKey) }
    }

    var appearance: Appearance {
        get { defaults.string(forKey: Self.appearanceKey).flatMap(Appearance.init(rawValue:)) ?? .system }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Self.appearanceKey) }
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
