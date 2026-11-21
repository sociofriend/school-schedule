import Foundation

/// Days in a row (newest first) on which every homework due that day was done. Days without homework are skipped.
enum HomeworkStreak {
    static func days(tasks: [(due: Date, isDone: Bool)], today: Date, calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: today)
        let byDay = Dictionary(grouping: tasks) { calendar.startOfDay(for: $0.due) }
        var streak = 0
        for day in byDay.keys.filter({ $0 <= today }).sorted(by: >) {
            let allDone = byDay[day]!.allSatisfy(\.isDone)
            if allDone { streak += 1 } else if day < today { break } // today may still be in progress
        }
        return streak
    }
}
