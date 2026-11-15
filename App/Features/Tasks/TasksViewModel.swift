import Combine
import Foundation
import Observation

@MainActor
@Observable
final class TasksViewModel {
    struct TaskGroup: Identifiable {
        let id: String
        let title: String
        let tasks: [TaskItem]
    }

    private(set) var groups: [TaskGroup] = []
    private(set) var remainingCount = 0
    private(set) var subjects: [String] = []
    var showsCompleted = false {
        didSet { reload() }
    }

    // Draft for the add sheet.
    var draftTitle = ""
    var draftSubject = ""
    var draftDue: Date = .now

    private let store: DataStore
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    init(store: DataStore) {
        self.store = store
        store.changes
            .sink { [weak self] in self?.reload() }
            .store(in: &cancellables)
        reload()
    }

    func reload(now: Date = .now) {
        let calendar = store.calendar
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let all = store.tasks()
        let open = all.filter { !$0.isDone }
        remainingCount = open.count
        subjects = store.timetable().subjects

        var result = [
            TaskGroup(id: "overdue", title: "Ուշացած", tasks: open.filter { $0.dueDate < today }),
            TaskGroup(id: "today", title: "Այսօր", tasks: open.filter { calendar.isDate($0.dueDate, inSameDayAs: today) }),
            TaskGroup(id: "tomorrow", title: "Վաղը", tasks: open.filter { calendar.isDate($0.dueDate, inSameDayAs: tomorrow) }),
            TaskGroup(id: "later", title: "Հետո", tasks: open.filter { $0.dueDate > tomorrow }),
        ]
        if showsCompleted {
            result.append(TaskGroup(id: "done", title: "Կատարված", tasks: all.filter(\.isDone).sorted {
                ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast)
            }))
        }
        groups = result.filter { !$0.tasks.isEmpty }
    }

    func prepareDraft() {
        draftTitle = ""
        draftSubject = ""
        draftDue = store.calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
    }

    /// Picking a subject moves the due date to its next lesson.
    func subjectChanged() {
        guard !draftSubject.isEmpty,
              let next = store.timetable().nextOccurrence(of: draftSubject, after: .now, calendar: store.calendar) else { return }
        draftDue = next
    }

    func saveDraft() {
        store.addTask(title: draftTitle, subject: draftSubject, due: draftDue)
    }

    func toggle(_ task: TaskItem) { store.toggle(task) }
    func delete(_ task: TaskItem) { store.delete(task) }

    func dueText(for task: TaskItem) -> String {
        task.dueDate.formatted(.dateTime.weekday().day().month())
    }
}
