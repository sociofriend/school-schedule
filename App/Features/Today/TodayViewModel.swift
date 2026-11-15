import Combine
import Foundation
import Observation

@MainActor
@Observable
final class TodayViewModel {
    private(set) var snapshot: DaySnapshot = .empty(.now)
    private(set) var isToday = true
    private(set) var currentPeriod: Int?
    private(set) var hasTimetable = false
    private(set) var subjectsWithNotes: Set<String> = []
    /// Increments each time the last open task is ticked off (drives the confetti).
    private(set) var celebrations = 0

    private let store: DataStore
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    init(store: DataStore) {
        self.store = store
        store.changes
            .merge(with: Timer.publish(every: 60, on: .main, in: .common).autoconnect().map { _ in () })
            .sink { [weak self] in self?.reload() }
            .store(in: &cancellables)
        reload()
    }

    var title: String {
        isToday ? "Այսօր" : "Վաղը՝ \(Weekday.name(store.calendar.component(.weekday, from: snapshot.date)))"
    }

    var greeting: (title: String, emoji: String) { Greeting.text() }
    var doneCount: Int { snapshot.tasks.count - snapshot.remainingTasks.count }
    var progress: Double { snapshot.tasks.isEmpty ? 0 : Double(doneCount) / Double(snapshot.tasks.count) }
    var cheer: String { Greeting.cheer(done: doneCount, total: snapshot.tasks.count) }
    var dayLabel: String {
        let name = Weekday.name(store.calendar.component(.weekday, from: snapshot.date))
        return isToday ? "Այսօր՝ \(name)" : "Վաղը՝ \(name)"
    }

    func reload(now: Date = .now) {
        let hadOpenTasks = !snapshot.remainingTasks.isEmpty
        let timetable = store.timetable()
        let day = timetable.focusDay(at: now, calendar: store.calendar)
        hasTimetable = !timetable.isEmpty
        isToday = store.calendar.isDate(day, inSameDayAs: now)
        snapshot = store.snapshot(for: day)
        currentPeriod = isToday ? timetable.currentOrNextPeriod(at: now, calendar: store.calendar) : nil
        subjectsWithNotes = Set(store.notes(on: day).map(\.subject))
        if hadOpenTasks, snapshot.remainingTasks.isEmpty, !snapshot.tasks.isEmpty { celebrations += 1 }
    }

    func toggle(_ task: TaskSummary) { store.toggleTask(task.id) }
}
