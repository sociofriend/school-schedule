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
    private let manualChanges = PassthroughSubject<Void, Never>()
    private var reader: ScheduleReader { ScheduleReader(context: context, calendar: calendar) }

    init(container: ModelContainer, calendar: Calendar = .current) {
        self.context = container.mainContext
        self.calendar = calendar
        let saves = NotificationCenter.default.publisher(for: ModelContext.didSave)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
        self.changes = Publishers.Merge(saves, manualChanges)
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

    // MARK: School Years & Timetable

    private static let seeded2026Key = "schedule.seeded.2026-2027"
    private static let customYearsKey = "schedule.customYears"

    var activeSchoolYear: String {
        get { SchoolYear.active }
        set {
            guard SchoolYear.active != newValue else { return }
            SchoolYear.active = newValue
            manualChanges.send()
        }
    }

    /// All known school years (stored in lessons, custom-added, or currently active), newest first.
    func schoolYears() -> [String] {
        var years = Set(fetch(FetchDescriptor<Lesson>()).map(\.schoolYear).filter { !$0.isEmpty })
        years.formUnion(AppGroup.defaults.stringArray(forKey: Self.customYearsKey) ?? [])
        years.insert(activeSchoolYear)
        return years.sorted { lhs, rhs in
            (SchoolYear.startYear(of: lhs) ?? 0) > (SchoolYear.startYear(of: rhs) ?? 0)
        }
    }

    func lessonCount(for schoolYear: String) -> Int {
        fetch(FetchDescriptor<Lesson>()).filter { $0.schoolYear == schoolYear }.count
    }

    func addSchoolYear(_ year: String) {
        let trimmed = year.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var custom = Set(AppGroup.defaults.stringArray(forKey: Self.customYearsKey) ?? [])
        custom.insert(trimmed)
        AppGroup.defaults.set(Array(custom), forKey: Self.customYearsKey)
        activeSchoolYear = trimmed
    }

    func deleteSchoolYear(_ year: String) {
        let years = schoolYears()
        guard years.count > 1 else { return }
        fetch(FetchDescriptor<Lesson>()).filter { $0.schoolYear == year }.forEach(context.delete)
        var custom = Set(AppGroup.defaults.stringArray(forKey: Self.customYearsKey) ?? [])
        custom.remove(year)
        AppGroup.defaults.set(Array(custom), forKey: Self.customYearsKey)
        save()
        if activeSchoolYear == year, let fallback = years.first(where: { $0 != year }) {
            activeSchoolYear = fallback
        } else {
            manualChanges.send()
        }
    }

    /// Migrates pre-year lessons into 2025-2026 and seeds the built-in 2026-2027 schedule once.
    func seedSchedulesIfNeeded() {
        let allLessons = fetch(FetchDescriptor<Lesson>())
        var mutated = false
        let legacyLessons = allLessons.filter { $0.schoolYear.isEmpty }
        if !legacyLessons.isEmpty {
            let targetYear = SchoolYear.legacyYear
            legacyLessons.forEach { $0.schoolYear = targetYear }
            mutated = true
        }

        let alreadySeeded = AppGroup.defaults.bool(forKey: Self.seeded2026Key)
        let has2026 = allLessons.contains { $0.schoolYear == SchoolYear.preset2026_2027Year }
        if !alreadySeeded && !has2026 {
            for entry in SchoolYear.preset2026_2027Entries {
                context.insert(Lesson(weekday: entry.weekday, period: entry.period, subject: entry.subject,
                                      room: entry.room, schoolYear: SchoolYear.preset2026_2027Year))
            }
            setPeriods(SchoolYear.preset2026_2027Periods, saving: false)
            SchoolYear.active = SchoolYear.preset2026_2027Year
            AppGroup.defaults.set(true, forKey: Self.seeded2026Key)
            mutated = true
        }

        if mutated {
            save()
            manualChanges.send()
        }
    }

    /// Restores the 2026-2027 timetable and bell schedule back to the hardcoded preset.
    func resetPreset2026_2027() {
        replaceTimetable(with: SchoolYear.preset2026_2027Entries,
                         periods: SchoolYear.preset2026_2027Periods,
                         for: SchoolYear.preset2026_2027Year)
        activeSchoolYear = SchoolYear.preset2026_2027Year
    }

    func timetable(for schoolYear: String? = nil) -> Timetable {
        (try? reader.timetable(for: schoolYear)) ?? Timetable()
    }

    func snapshot(for day: Date, timetable: Timetable? = nil) -> DaySnapshot {
        (try? reader.snapshot(for: day, timetable: timetable ?? self.timetable())) ?? .empty(day)
    }

    func replaceTimetable(with entries: [TimetableEntry], periods: [Int: PeriodRange] = [:], for schoolYear: String? = nil) {
        let year = schoolYear ?? activeSchoolYear
        fetch(FetchDescriptor<Lesson>()).filter { $0.schoolYear == year }.forEach(context.delete)
        entries.forEach {
            context.insert(Lesson(weekday: $0.weekday, period: $0.period, subject: $0.subject,
                                  room: $0.room, schoolYear: year))
        }
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

    /// Markers per day (start of day): homework due, notes, photos, tests.
    func dayMarks() -> [Date: DayMarks] {
        var marks: [Date: DayMarks] = [:]
        for task in tasks() {
            let day = calendar.startOfDay(for: task.dueDate)
            if task.isDone { marks[day, default: DayMarks()].doneHomework += 1 }
            else { marks[day, default: DayMarks()].pendingHomework += 1 }
            if DayMarks.isTest(task.title) { marks[day, default: DayMarks()].hasTest = true }
        }
        for note in allNotes() {
            let day = calendar.startOfDay(for: note.day)
            if !note.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { marks[day, default: DayMarks()].hasNote = true }
            if !note.photos.isEmpty { marks[day, default: DayMarks()].hasPhoto = true }
        }
        return marks
    }
}
