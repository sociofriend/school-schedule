import XCTest
@testable import SchoolSchedule

final class TimetableTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Yerevan")!
        return calendar
    }()

    // 2026-11-16 is a Monday.
    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    private let timetable = Timetable(
        entries: [
            TimetableEntry(weekday: 2, period: 1, subject: "Math"),
            TimetableEntry(weekday: 2, period: 2, subject: "Art"),
            TimetableEntry(weekday: 4, period: 1, subject: "Math"),
        ],
        periods: [1: PeriodRange(start: 540, end: 585), 2: PeriodRange(start: 595, end: 640)]
    )

    func testFocusDayIsTodayDuringSchool() {
        XCTAssertEqual(timetable.focusDay(at: date(16, 10), calendar: calendar), calendar.startOfDay(for: date(16, 0)))
    }

    func testFocusDayMovesToNextSchoolDayAfterLastLesson() {
        XCTAssertEqual(timetable.focusDay(at: date(16, 11), calendar: calendar), calendar.startOfDay(for: date(18, 0)))
    }

    func testCurrentOrNextPeriod() {
        XCTAssertEqual(timetable.currentOrNextPeriod(at: date(16, 9, 10), calendar: calendar), 1)
        XCTAssertEqual(timetable.currentOrNextPeriod(at: date(16, 9, 50), calendar: calendar), 2)
        XCTAssertNil(timetable.currentOrNextPeriod(at: date(16, 12), calendar: calendar))
    }

    func testNextOccurrence() {
        XCTAssertEqual(timetable.nextOccurrence(of: "Math", after: date(16, 10), calendar: calendar), calendar.startOfDay(for: date(18, 0)))
        XCTAssertEqual(timetable.nextOccurrence(of: "Art", after: date(16, 10), calendar: calendar), calendar.startOfDay(for: date(23, 0)))
    }
}
