import Combine
import Foundation
import OSLog
import SwiftData

/// Single write gateway to SwiftData for all view models.
@MainActor
final class DataStore {
    let context: ModelContext
    let calendar: Calendar
    /// Emits on the main queue after any context of the container saves.
    let changes: AnyPublisher<Void, Never>

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Dasacucak", category: "DataStore")
    private var reader: ScheduleReader { ScheduleReader(context: context, calendar: calendar) }

    init(container: ModelContainer, calendar: Calendar = .current) {
        self.context = container.mainContext
        self.calendar = calendar
        self.changes = NotificationCenter.default.publisher(for: ModelContext.didSave)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func save() {
        guard context.hasChanges else { return }
        do { try context.save() } catch { logger.error("Save failed: \(error.localizedDescription)") }
    }

    private func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) -> [T] {
        do { return try context.fetch(descriptor) } catch {
            logger.error("Fetch failed: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: Timetable

    func timetable() -> Timetable { (try? reader.timetable()) ?? Timetable() }

    func snapshot(for day: Date, timetable: Timetable? = nil) -> DaySnapshot {
        (try? reader.snapshot(for: day, timetable: timetable ?? self.timetable())) ?? .empty(day)
    }

    func replaceTimetable(with entries: [TimetableEntry], periods: [Int: PeriodRange] = [:]) {
        fetch(FetchDescriptor<Lesson>()).forEach(context.delete)
        entries.forEach { context.insert(Lesson(weekday: $0.weekday, period: $0.period, subject: $0.subject, room: $0.room)) }
        if !periods.isEmpty { setPeriods(periods, saving: false) }
        save()
    }

    func periodTimes() -> [PeriodTime] {
        fetch(FetchDescriptor<PeriodTime>(sortBy: [SortDescriptor(\.period)]))
    }

    func setPeriods(_ ranges: [Int: PeriodRange], saving: Bool = true) {
        let existing = Dictionary(periodTimes().map { ($0.period, $0) }, uniquingKeysWith: { first, _ in first })
        for (period, range) in ranges {
            if let time = existing[period] {
                time.startMinute = range.start
                time.endMinute = range.end
            } else {
                context.insert(PeriodTime(period: period, startMinute: range.start, endMinute: range.end))
            }
        }
        if saving { save() }
    }

    func deletePeriod(_ time: PeriodTime) {
        context.delete(time)
        save()
    }

    func seedDefaultPeriodsIfNeeded() {
        guard periodTimes().isEmpty else { return }
        setPeriods(PeriodTime.defaultRanges)
    }

    // MARK: Notes

    func note(on day: Date, subject: String) -> LessonNote? {
        let start = calendar.startOfDay(for: day)
        var descriptor = FetchDescriptor<LessonNote>(predicate: #Predicate { $0.day == start && $0.subject == subject })
        descriptor.fetchLimit = 1
        return fetch(descriptor).first
    }

    func noteCreatingIfNeeded(on day: Date, subject: String) -> LessonNote {
        if let note = note(on: day, subject: subject) { return note }
        let note = LessonNote(day: calendar.startOfDay(for: day), subject: subject)
        context.insert(note)
        return note
    }

    func allNotes() -> [LessonNote] {
        fetch(FetchDescriptor<LessonNote>(sortBy: [SortDescriptor(\.day, order: .reverse)])).filter { !$0.isEmpty }
    }

    func notes(on day: Date) -> [LessonNote] {
        let start = calendar.startOfDay(for: day)
        return fetch(FetchDescriptor<LessonNote>(predicate: #Predicate { $0.day == start })).filter { !$0.isEmpty }
    }

    func addPhoto(_ data: Data, to note: LessonNote) {
        let photo = NotePhoto(imageData: data)
        context.insert(photo)
        photo.note = note
        note.updatedAt = .now
        save()
    }

    func deletePhoto(_ photo: NotePhoto) {
        context.delete(photo)
        save()
    }

    /// Removes notes left empty (e.g. opened but never written).
    func pruneIfEmpty(_ note: LessonNote) {
        if note.isEmpty { context.delete(note) }
        save()
    }

    // MARK: Tasks

    func tasks() -> [TaskItem] {
        fetch(FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.dueDate), SortDescriptor(\.createdAt)]))
    }

    func tasks(subject: String, around day: Date) -> [TaskItem] {
        let start = calendar.startOfDay(for: day)
        let assigned: Date? = start
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { $0.subject == subject && ($0.dueDate == start || $0.assignedOn == assigned) },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return fetch(descriptor)
    }

    @discardableResult
    func addTask(title: String, subject: String = "", due: Date, assignedOn: Date? = nil) -> TaskItem? {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }
        let task = TaskItem(title: title, subject: subject, dueDate: calendar.startOfDay(for: due),
                            assignedOn: assignedOn.map(calendar.startOfDay(for:)))
        context.insert(task)
        save()
        return task
    }

    func toggleTask(_ id: PersistentIdentifier) {
        guard let task = context.model(for: id) as? TaskItem else { return }
        toggle(task)
    }

    func toggle(_ task: TaskItem) {
        task.setDone(!task.isDone)
        save()
    }

    func delete(_ task: TaskItem) {
        context.delete(task)
        save()
    }

    // MARK: Calendar

    /// Days that have notes or open tasks, as year/month/day components.
    func markedDays() -> Set<DateComponents> {
        let days = allNotes().map(\.day) + tasks().filter { !$0.isDone }.map(\.dueDate)
        return Set(days.map { calendar.dateComponents([.year, .month, .day], from: $0) })
    }
}
