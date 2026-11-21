import Foundation

/// Minutes from midnight.
struct PeriodRange: Hashable, Sendable, Codable {
    var start: Int
    var end: Int
}

struct TimetableEntry: Hashable, Sendable {
    var weekday: Int
    var period: Int
    var subject: String
    var room: String = ""
}

/// One lesson placed on a concrete date.
struct LessonSlot: Hashable, Sendable, Identifiable {
    var id: Int { period }
    let period: Int
    let subject: String
    let room: String
    let start: Date?
    let end: Date?
}

/// Where the school day stands at a moment.
enum DayPhase: Hashable, Sendable {
    case beforeSchool(first: LessonSlot)
    case inLesson(LessonSlot, next: LessonSlot?)
    case onBreak(next: LessonSlot)
    case finished
}

/// Value-type timetable with all scheduling rules. Shared by app, widget and notifications.
struct Timetable: Sendable {
    var entries: [TimetableEntry] = []
    var periods: [Int: PeriodRange] = [:]

    var isEmpty: Bool { entries.isEmpty }

    var subjects: [String] {
        Array(Set(entries.map(\.subject))).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    func slots(on date: Date, calendar: Calendar = .current) -> [LessonSlot] {
        let weekday = calendar.component(.weekday, from: date)
        let day = calendar.startOfDay(for: date)
        return entries
            .filter { $0.weekday == weekday }
            .sorted { $0.period < $1.period }
            .map { entry in
                let range = periods[entry.period]
                return LessonSlot(
                    period: entry.period,
                    subject: entry.subject,
                    room: entry.room,
                    start: range.map { day.adding(minutes: $0.start, calendar: calendar) },
                    end: range.map { day.adding(minutes: $0.end, calendar: calendar) }
                )
            }
    }

    func hasLessons(on date: Date, calendar: Calendar = .current) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return entries.contains { $0.weekday == weekday }
    }

    /// End of the last lesson on `date`, if bell times are known.
    func endOfSchool(on date: Date, calendar: Calendar = .current) -> Date? {
        slots(on: date, calendar: calendar).compactMap(\.end).max()
    }

    /// First day strictly after `date` that has lessons (searches one week).
    func nextSchoolDay(after date: Date, calendar: Calendar = .current) -> Date? {
        let start = calendar.startOfDay(for: date)
        return (1...7)
            .compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
            .first { hasLessons(on: $0, calendar: calendar) }
    }

    /// Next day strictly after `date` on which `subject` is taught.
    func nextOccurrence(of subject: String, after date: Date, calendar: Calendar = .current) -> Date? {
        let start = calendar.startOfDay(for: date)
        return (1...7)
            .compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
            .first { day in
                let weekday = calendar.component(.weekday, from: day)
                return entries.contains { $0.weekday == weekday && $0.subject == subject }
            }
    }

    /// The day the user cares about now: today until its last lesson ends, then the next school day.
    func focusDay(at now: Date, calendar: Calendar = .current) -> Date {
        let today = calendar.startOfDay(for: now)
        if hasLessons(on: now, calendar: calendar) {
            let end = endOfSchool(on: now, calendar: calendar)
                ?? today.adding(minutes: 15 * 60, calendar: calendar)
            if now < end { return today }
        }
        return nextSchoolDay(after: now, calendar: calendar)
            ?? calendar.date(byAdding: .day, value: 1, to: today)
            ?? today
    }

    /// Lesson running at `now`, or the next one today if between lessons.
    func currentOrNextPeriod(at now: Date, calendar: Calendar = .current) -> Int? {
        slots(on: now, calendar: calendar).first { ($0.end ?? .distantPast) > now }?.period
    }

    /// Where today stands at `now`, for the "now" card. `nil` when there are no lessons or no bell times.
    func phase(at now: Date, calendar: Calendar = .current) -> DayPhase? {
        let slots = slots(on: now, calendar: calendar).filter { $0.start != nil && $0.end != nil }
        guard !slots.isEmpty else { return nil }
        guard let index = slots.firstIndex(where: { $0.end! > now }) else { return .finished }
        let slot = slots[index]
        if slot.start! <= now { return .inLesson(slot, next: slots.indices.contains(index + 1) ? slots[index + 1] : nil) }
        return index == 0 ? .beforeSchool(first: slot) : .onBreak(next: slot)
    }

    /// Lessons that have already ended today.
    func lessonsDone(at now: Date, calendar: Calendar = .current) -> Int {
        slots(on: now, calendar: calendar).filter { ($0.end ?? .distantFuture) <= now }.count
    }

    /// Times when the widget must refresh today (each lesson start/end after `now`).
    func boundaries(after now: Date, calendar: Calendar = .current) -> [Date] {
        slots(on: now, calendar: calendar)
            .flatMap { [$0.start, $0.end].compactMap { $0 } }
            .filter { $0 > now }
            .sorted()
    }
}

extension Date {
    func adding(minutes: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .minute, value: minutes, to: self) ?? self
    }
}

extension PeriodRange {
    static func format(_ minute: Int) -> String {
        String(format: "%02d:%02d", minute / 60, minute % 60)
    }

    var formatted: String { "\(Self.format(start))–\(Self.format(end))" }
}
