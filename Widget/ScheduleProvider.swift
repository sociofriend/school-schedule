import SwiftData
import WidgetKit

struct ScheduleEntry: TimelineEntry {
    let date: Date
    let snapshot: DaySnapshot
    let isToday: Bool
    let currentPeriod: Int?
    let hasTimetable: Bool
    var phase: DayPhase?

    static let placeholder: ScheduleEntry = {
        let now = Date()
        let lessons = ["Մաթեմատիկա", "Հայոց լեզու", "Անգլերեն", "Ֆիզիկա", "Պատմություն"].enumerated().map { index, subject in
            LessonSlot(period: index + 1, subject: subject, room: "", start: now.adding(minutes: index * 55), end: now.adding(minutes: index * 55 + 45))
        }
        return ScheduleEntry(date: now, snapshot: DaySnapshot(date: now, lessons: lessons, tasks: []), isToday: true, currentPeriod: 1, hasTimetable: true,
                             phase: .inLesson(lessons[0], next: lessons[1]))
    }()
}

/// Today's lessons while school is on, the next school day's lessons and tasks afterwards.
struct ScheduleProvider: TimelineProvider {
    func placeholder(in context: Context) -> ScheduleEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        completion(context.isPreview ? .placeholder : (try? makeEntries(from: .now).first) ?? .placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now.addingTimeInterval(3600)
        let entries = (try? makeEntries(from: now)) ?? [.placeholder]
        completion(Timeline(entries: entries, policy: .after(midnight)))
    }

    private func makeEntries(from now: Date) throws -> [ScheduleEntry] {
        let calendar = Calendar.current
        let reader = ScheduleReader(context: ModelContext(SharedModelContainer.shared), calendar: calendar)
        let timetable = try reader.timetable()
        let dates = [now] + timetable.boundaries(after: now, calendar: calendar)
        return try dates.map { date in
            let day = timetable.focusDay(at: date, calendar: calendar)
            let isToday = calendar.isDate(day, inSameDayAs: date)
            return ScheduleEntry(
                date: date,
                snapshot: try reader.snapshot(for: day, timetable: timetable),
                isToday: isToday,
                currentPeriod: isToday ? timetable.currentOrNextPeriod(at: date, calendar: calendar) : nil,
                hasTimetable: !timetable.isEmpty,
                phase: isToday ? timetable.phase(at: date, calendar: calendar) : nil
            )
        }
    }
}
