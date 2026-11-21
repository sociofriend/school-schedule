import Foundation

/// iOS ships no Armenian UI, so the app pins dates and pickers to `hy_AM` itself rather than following the device region.
extension Locale {
    static let armenian = Locale(identifier: "hy_AM")
}

extension Date {
    /// "09:00"
    var armenianTime: String { formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute().locale(.armenian)) }
    /// "երկուշաբթի, 16 նոյեմբերի"
    var armenianLongDay: String { formatted(.dateTime.weekday(.wide).day().month(.wide).locale(.armenian)) }
    /// "երկ, 16 նոյ"
    var armenianShortDay: String { formatted(.dateTime.weekday().day().month().locale(.armenian)) }
}
