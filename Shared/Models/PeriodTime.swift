import Foundation
import SwiftData

/// User-editable bell schedule: start/end of a lesson number, in minutes from midnight.
@Model
final class PeriodTime {
    @Attribute(.unique) var period: Int
    var startMinute: Int
    var endMinute: Int

    init(period: Int, startMinute: Int, endMinute: Int) {
        self.period = period
        self.startMinute = startMinute
        self.endMinute = endMinute
    }

    var range: PeriodRange { PeriodRange(start: startMinute, end: endMinute) }

    /// Typical 45-minute bell schedule used as a starting point.
    static let defaultRanges: [Int: PeriodRange] = [
        1: .init(start: 9 * 60, end: 9 * 60 + 45),
        2: .init(start: 9 * 60 + 55, end: 10 * 60 + 40),
        3: .init(start: 10 * 60 + 50, end: 11 * 60 + 35),
        4: .init(start: 11 * 60 + 55, end: 12 * 60 + 40),
        5: .init(start: 12 * 60 + 50, end: 13 * 60 + 35),
        6: .init(start: 13 * 60 + 45, end: 14 * 60 + 30),
        7: .init(start: 14 * 60 + 40, end: 15 * 60 + 25),
    ]
}
