import Foundation

/// App Group shared by the app and the widget extension.
enum AppGroup {
    static let identifier: String = {
        guard let id = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String, !id.isEmpty else {
            fatalError("AppGroupIdentifier is missing from Info.plist")
        }
        return id
    }()

    /// Kid's school grade (1...12), written by `ProfileStore`, read by subject icons in the app and widget.
    static let gradeKey = "profile.grade"
    /// Active academic year (e.g. "2026-2027"), shared by the app and widget.
    static let schoolYearKey = "schedule.schoolYear"

    static var defaults: UserDefaults { UserDefaults(suiteName: identifier) ?? .standard }
}
