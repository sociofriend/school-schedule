import Foundation
import SwiftData

/// One cell of the weekly timetable.
@Model
final class Lesson {
    /// `Calendar` weekday: 1 = Sunday … 7 = Saturday.
    var weekday: Int
    /// 1-based lesson number within the day.
    var period: Int
    var subject: String
    /// Classroom for students, class name (e.g. "7Ա") for teachers.
    var room: String

    init(weekday: Int, period: Int, subject: String, room: String = "") {
        self.weekday = weekday
        self.period = period
        self.subject = subject
        self.room = room
    }
}
