import Foundation
import SwiftData

struct TaskSummary: Hashable, Sendable, Identifiable {
    let id: PersistentIdentifier
    let title: String
    let subject: String
    let isDone: Bool
}

/// Everything shown for one day: lessons and the tasks due that day.
struct DaySnapshot: Sendable {
    let date: Date
    let lessons: [LessonSlot]
    let tasks: [TaskSummary]

    var isEmpty: Bool { lessons.isEmpty && tasks.isEmpty }
    var remainingTasks: [TaskSummary] { tasks.filter { !$0.isDone } }

    static func empty(_ date: Date) -> DaySnapshot { DaySnapshot(date: date, lessons: [], tasks: []) }
}
