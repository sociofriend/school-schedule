import Foundation

/// Evening reminder preferences, stored in the App Group.
struct ReminderSettings: Equatable {
    var isEnabled = true
    /// Minutes from midnight. Default 20:00.
    var minuteOfDay = 20 * 60

    private static let enabledKey = "reminder.enabled"
    private static let minuteKey = "reminder.minute"

    static func load(from defaults: UserDefaults = AppGroup.defaults) -> ReminderSettings {
        var settings = ReminderSettings()
        if defaults.object(forKey: enabledKey) != nil { settings.isEnabled = defaults.bool(forKey: enabledKey) }
        if defaults.object(forKey: minuteKey) != nil { settings.minuteOfDay = defaults.integer(forKey: minuteKey) }
        return settings
    }

    func save(to defaults: UserDefaults = AppGroup.defaults) {
        defaults.set(isEnabled, forKey: Self.enabledKey)
        defaults.set(minuteOfDay, forKey: Self.minuteKey)
    }
}
