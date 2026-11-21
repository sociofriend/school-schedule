import Foundation

/// What a calendar day holds, drawn as small markers under its number.
struct DayMarks: Equatable, Sendable {
    var pendingHomework = 0
    var doneHomework = 0
    var hasNote = false
    var hasPhoto = false
    var hasTest = false

    var isEmpty: Bool { self == DayMarks() }
    /// Every task due that day is done.
    var allDone: Bool { pendingHomework == 0 && doneHomework > 0 }

    /// Words that mark a task as a test or quiz (Armenian and Latin spellings).
    static let testWords = ["ստուգողական", "թեստ", "գրավոր", "կոնտրոլ", "ամփոփիչ", "test", "quiz"]

    static func isTest(_ title: String) -> Bool {
        let title = title.lowercased()
        return testWords.contains { title.contains($0) }
    }
}
