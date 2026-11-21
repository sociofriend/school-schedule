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
    /// Open tasks due by tomorrow (tab badge), so far-off homework does not nag.
    private(set) var dueSoonCount = 0
    /// Stars earned: tasks completed in the last 7 days.
    private(set) var starsThisWeek = 0
    private(set) var celebrations = 0
    /// Days in a row with all homework done.
    private(set) var streak = 0
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
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        if remainingCount > 0, open.isEmpty, !all.isEmpty { celebrations += 1 }
        remainingCount = open.count
        dueSoonCount = open.filter { $0.dueDate <= tomorrow }.count
        starsThisWeek = all.filter { ($0.completedAt ?? .distantPast) > weekAgo }.count
        subjects = store.timetable().subjects
        streak = HomeworkStreak.days(tasks: all.map { (due: $0.dueDate, isDone: $0.isDone) }, today: now, calendar: calendar)

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

    /// One-tap titles so kids type less.
    static let quickTitles = ["Վարժություն", "Կարդալ", "Անգիր սովորել", "Խնդիրներ", "Շարադրություն", "Նախագիծ"]

    func prepareDraft(subject: String = "") {
        draftTitle = ""
        draftSubject = subject
        draftDue = store.calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
        subjectChanged()
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

    var progress: Double {
        let total = starsThisWeek + remainingCount
        return total == 0 ? 0 : Double(starsThisWeek) / Double(total)
    }

    var cheer: String { Greeting.cheer(done: starsThisWeek, total: starsThisWeek + remainingCount) }

    func toggle(_ task: TaskItem) { store.toggle(task) }
    func delete(_ task: TaskItem) { store.delete(task) }

    func dueText(for task: TaskItem) -> String {
        task.dueDate.formatted(.dateTime.weekday().day().month())
    }
}
