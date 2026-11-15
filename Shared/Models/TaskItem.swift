import Foundation
import SwiftData

/// Homework or any to-do. Feeds the automatic checklist.
@Model
final class TaskItem {
    var title: String
    /// Empty when not tied to a subject.
    var subject: String
    /// Start of the day it is due.
    var dueDate: Date
    /// Start of the day it was assigned (lesson day), if created from a lesson.
    var assignedOn: Date?
    var isDone: Bool
    var completedAt: Date?
    var createdAt: Date

    init(title: String, subject: String = "", dueDate: Date, assignedOn: Date? = nil) {
        self.title = title
        self.subject = subject
        self.dueDate = dueDate
        self.assignedOn = assignedOn
        self.isDone = false
        self.createdAt = .now
    }

    func setDone(_ done: Bool) {
        isDone = done
        completedAt = done ? .now : nil
    }
}
