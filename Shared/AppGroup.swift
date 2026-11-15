import Foundation

/// App Group shared by the app and the widget extension.
enum AppGroup {
    static let identifier: String = {
        guard let id = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String, !id.isEmpty else {
            fatalError("AppGroupIdentifier is missing from Info.plist")
        }
        return id
    }()

    static var defaults: UserDefaults { UserDefaults(suiteName: identifier) ?? .standard }
}
