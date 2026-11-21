import Foundation

/// iOS ships no Armenian UI, so the app pins dates and pickers to `hy_AM` itself rather than following the device region.
extension Locale {
    static let armenian = Locale(identifier: "hy_AM")
}

extension Date {
    /// Always zero-padded 24-hour "09:05", the one time format used app-wide (same as `PeriodRange.format`).
    func armenianTime(calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.hour, .minute], from: self)
        return PeriodRange.format((c.hour ?? 0) * 60 + (c.minute ?? 0))
    }
    /// "երկուշաբթի, 16 նոյեմբերի"
    var armenianLongDay: String { formatted(.dateTime.weekday(.wide).day().month(.wide).locale(.armenian)) }
    /// "երկ, 16 նոյ"
    var armenianShortDay: String { formatted(.dateTime.weekday().day().month().locale(.armenian)) }
}
