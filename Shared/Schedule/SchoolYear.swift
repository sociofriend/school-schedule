import Foundation

/// Academic year identifier (e.g. "2026-2027") and built-in schedule presets.
enum SchoolYear {
    static let preset2026_2027Year = "2026-2027"
    static let legacyYear = "2025-2026"

    /// Academic year containing `date` (starts in September in Armenia).
    static func current(for date: Date = .now, calendar: Calendar = .current) -> String {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        return month >= 9 ? "\(year)-\(year + 1)" : "\(year - 1)-\(year)"
    }

    /// Active school year shared between the app and widget via App Group defaults.
    static var active: String {
        get {
            if let saved = AppGroup.defaults.string(forKey: AppGroup.schoolYearKey), !saved.isEmpty {
                return saved
            }
            return current()
        }
        set {
            AppGroup.defaults.set(newValue, forKey: AppGroup.schoolYearKey)
        }
    }

    /// Next academic year after `year` (e.g. "2026-2027" → "2027-2028").
    static func next(after year: String) -> String {
        guard let start = startYear(of: year) else { return current() }
        return "\(start + 1)-\(start + 2)"
    }

    /// Previous academic year before `year` (e.g. "2026-2027" → "2025-2026").
    static func previous(before year: String) -> String {
        guard let start = startYear(of: year) else { return legacyYear }
        return "\(start - 1)-\(start)"
    }

    static func startYear(of year: String) -> Int? {
        year.split(separator: "-").first.flatMap { Int($0) }
    }

    /// Hardcoded 2026-2027 weekly timetable and bell schedule.
    static let preset2026_2027Periods: [Int: PeriodRange] = [
        1: PeriodRange(start: 8 * 60 + 15, end: 9 * 60 + 0),   // 08:15 – 09:00
        2: PeriodRange(start: 9 * 60 + 5, end: 9 * 60 + 50),   // 09:05 – 09:50
        3: PeriodRange(start: 9 * 60 + 55, end: 10 * 60 + 40), // 09:55 – 10:40
        4: PeriodRange(start: 11 * 60 + 10, end: 11 * 60 + 55), // 11:10 – 11:55
        5: PeriodRange(start: 12 * 60 + 0, end: 12 * 60 + 45), // 12:00 – 12:45
        6: PeriodRange(start: 12 * 60 + 50, end: 13 * 60 + 35), // 12:50 – 13:35
        7: PeriodRange(start: 13 * 60 + 40, end: 14 * 60 + 25), // 13:40 – 14:25
        8: PeriodRange(start: 14 * 60 + 30, end: 15 * 60 + 15), // 14:30 – 15:15
    ]

    static let preset2026_2027Entries: [TimetableEntry] = [
        // Երկուշաբթի (Monday = 2)
        TimetableEntry(weekday: 2, period: 1, subject: "Մաթեմատիկայի հատուկ դասընթաց"),
        TimetableEntry(weekday: 2, period: 2, subject: "Ֆիզկուլտուրա"),
        TimetableEntry(weekday: 2, period: 3, subject: "Հանրահաշիվ"),
        TimetableEntry(weekday: 2, period: 4, subject: "Հանրահաշիվ"),
        TimetableEntry(weekday: 2, period: 5, subject: "Աշխարհագրություն"),
        TimetableEntry(weekday: 2, period: 7, subject: "Հայաստանի պատմություն"),
        TimetableEntry(weekday: 2, period: 8, subject: "Ֆրանսերեն / Առողջ ապրելակերպ"),

        // Երեքշաբթի (Tuesday = 3)
        TimetableEntry(weekday: 3, period: 1, subject: "Երկրաչափություն"),
        TimetableEntry(weekday: 3, period: 2, subject: "Երկրաչափություն"),
        TimetableEntry(weekday: 3, period: 3, subject: "Հայոց լեզու"),
        TimetableEntry(weekday: 3, period: 4, subject: "Կենսաբանություն"),
        TimetableEntry(weekday: 3, period: 5, subject: "Արվեստ"),
        TimetableEntry(weekday: 3, period: 6, subject: "Համաշխարհային պատմություն"),
        TimetableEntry(weekday: 3, period: 8, subject: "Ֆրանսերեն"),

        // Չորեքշաբթի (Wednesday = 4)
        TimetableEntry(weekday: 4, period: 1, subject: "Հայոց լեզու"),
        TimetableEntry(weekday: 4, period: 2, subject: "Գրականություն"),
        TimetableEntry(weekday: 4, period: 3, subject: "Ռուսաց լեզու"),
        TimetableEntry(weekday: 4, period: 4, subject: "Ֆիզիկա"),
        TimetableEntry(weekday: 4, period: 5, subject: "Քիմիա"),
        TimetableEntry(weekday: 4, period: 6, subject: "Ֆիզիկա"),
        TimetableEntry(weekday: 4, period: 7, subject: "Աշխարհագրություն"),

        // Հինգշաբթի (Thursday = 5)
        TimetableEntry(weekday: 5, period: 1, subject: "Հանրահաշիվ"),
        TimetableEntry(weekday: 5, period: 2, subject: "Հանրահաշիվ"),
        TimetableEntry(weekday: 5, period: 3, subject: "Ռուսաց լեզու"),
        TimetableEntry(weekday: 5, period: 4, subject: "Համաշխարհային պատմություն"),
        TimetableEntry(weekday: 5, period: 5, subject: "Հայաստանի պատմություն"),
        TimetableEntry(weekday: 5, period: 6, subject: "Կենսաբանություն"),
        TimetableEntry(weekday: 5, period: 7, subject: "Թվային գրագիտություն և համակարգչային գիտություն"),

        // Ուրբաթ (Friday = 6)
        TimetableEntry(weekday: 6, period: 1, subject: "Երկրաչափություն"),
        TimetableEntry(weekday: 6, period: 2, subject: "Ֆիզկուլտուրա"),
        TimetableEntry(weekday: 6, period: 3, subject: "Գրականություն"),
        TimetableEntry(weekday: 6, period: 4, subject: "Քիմիա"),
        TimetableEntry(weekday: 6, period: 5, subject: "Ֆիզիկա"),
        TimetableEntry(weekday: 6, period: 6, subject: "Հասարակագիտություն"),
        TimetableEntry(weekday: 6, period: 7, subject: "Հայաստանի պատմություն"),
    ]
}
