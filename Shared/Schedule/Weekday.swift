import Foundation

/// Weekday helpers using `Calendar` numbering (1 = Sunday).
enum Weekday {
    /// School week order, Monday first.
    static let schoolWeek = [2, 3, 4, 5, 6, 7]

    private static let armenian: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "hy_AM")
        return calendar
    }()

    static func name(_ weekday: Int) -> String {
        armenian.standaloneWeekdaySymbols[weekday - 1].capitalized(with: armenian.locale)
    }

    static func shortName(_ weekday: Int) -> String {
        armenian.shortStandaloneWeekdaySymbols[weekday - 1].capitalized(with: armenian.locale)
    }
}
