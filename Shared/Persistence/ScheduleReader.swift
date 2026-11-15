import Foundation
import SwiftData

/// Read-only queries shared by the app, widget and notification scheduler.
struct ScheduleReader {
    let context: ModelContext
    var calendar: Calendar = .current

    func timetable() throws -> Timetable {
        let lessons = try context.fetch(FetchDescriptor<Lesson>())
        let periods = try context.fetch(FetchDescriptor<PeriodTime>())
        return Timetable(
            entries: lessons.map { TimetableEntry(weekday: $0.weekday, period: $0.period, subject: $0.subject, room: $0.room) },
            periods: Dictionary(periods.map { ($0.period, $0.range) }, uniquingKeysWith: { first, _ in first })
        )
    }

    func tasks(dueOn day: Date) throws -> [TaskItem] {
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.dueDate >= start && $0.dueDate < end },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor)
    }

    func snapshot(for day: Date, timetable: Timetable) throws -> DaySnapshot {
        let tasks = try tasks(dueOn: day)
            .sorted { !$0.isDone && $1.isDone }
            .map { TaskSummary(id: $0.persistentModelID, title: $0.title, subject: $0.subject, isDone: $0.isDone) }
        return DaySnapshot(date: calendar.startOfDay(for: day), lessons: timetable.slots(on: day, calendar: calendar), tasks: tasks)
    }
}
