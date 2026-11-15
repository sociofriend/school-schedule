import Foundation

/// Navigation value for a lesson on a concrete day.
struct LessonRoute: Hashable {
    let day: Date
    let subject: String
}
