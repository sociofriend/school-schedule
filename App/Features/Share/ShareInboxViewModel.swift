import Foundation
import Observation

/// A received share: shows what came, then lets the kid choose where it goes before saving.
@MainActor
@Observable
final class ShareInboxViewModel {
    enum TimetableMode: Hashable { case replace, merge }

    private(set) var package: SharePackage?
    var failed = false

    // Task placement.
    var subject = ""
    var due: Date = .now
    private(set) var subjects: [String] = []

    // Timetable placement.
    var mode: TimetableMode = .replace
    var takesBellTimes = true
    private(set) var hasOwnTimetable = false

    private let store: DataStore

    init(store: DataStore) { self.store = store }

    /// Called for files opened with the app (AirDrop, Messages, Files).
    func open(_ url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url), let package = try? SharePackage.decode(data),
              package.version <= SharePackage.currentVersion else {
            failed = true
            return
        }
        receive(package)
    }

    func receive(_ package: SharePackage) {
        let mine = store.timetable()
        subjects = mine.subjects
        hasOwnTimetable = !mine.isEmpty
        switch package.content {
        case .task(let task):
            subject = subjects.contains(task.subject) ? task.subject : ""
            let today = store.calendar.startOfDay(for: .now)
            due = task.dueDate >= today ? task.dueDate : (store.calendar.date(byAdding: .day, value: 1, to: today) ?? today)
        case .timetable(let timetable):
            mode = hasOwnTimetable ? .merge : .replace
            takesBellTimes = !timetable.periods.isEmpty
        }
        self.package = package
    }

    /// Picking a subject moves the due date to its next lesson (same rule as the add sheet).
    func subjectChanged() {
        guard !subject.isEmpty,
              let next = store.timetable().nextOccurrence(of: subject, after: .now, calendar: store.calendar) else { return }
        due = next
    }

    func accept() {
        guard let package else { return }
        switch package.content {
        case .task(let task):
            store.addTask(title: task.title, subject: subject, due: due)
        case .timetable(let incoming):
            let target = mode == .merge ? store.timetable().merged(with: incoming) : incoming
            // Merge only fills missing bell times; replace takes them if the kid wants.
            store.replaceTimetable(with: target.entries, periods: mode == .merge || takesBellTimes ? target.periods : [:])
        }
        self.package = nil
    }

    func decline() { package = nil }
}
