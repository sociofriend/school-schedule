import XCTest
@testable import SchoolSchedule

/// Tests for SharePackage.
final class SharePackageTests: XCTestCase {
    private let timetable = Timetable(
        entries: [
            TimetableEntry(weekday: 2, period: 1, subject: "Մաթեմատիկա"),
            TimetableEntry(weekday: 2, period: 2, subject: "Երաժշտություն", room: "12"),
        ],
        periods: [1: PeriodRange(start: 540, end: 585)]
    )

    func testRoundTripsTimetable() throws {
        let package = SharePackage(sender: "Անի", content: .timetable(timetable))
        let decoded = try SharePackage.decode(package.encoded())
        XCTAssertEqual(decoded.content, package.content)
        XCTAssertEqual(decoded.sender, "Անի")
    }

    func testRoundTripsTask() throws {
        let task = SharePackage.Task(title: "Խնդիրներ 12–15", subject: "Մաթեմատիկա", dueDate: Date(timeIntervalSince1970: 1_800_000_000))
        let decoded = try SharePackage.decode(SharePackage(sender: "", content: .task(task)).encoded())
        XCTAssertEqual(decoded.content, .task(task))
    }

    func testReadableTextListsLessonsWithTimes() {
        let text = SharePackage(sender: "Անի", content: .timetable(timetable)).readableText
        XCTAssertTrue(text.contains("1. Մաթեմատիկա (09:00)"))
        XCTAssertTrue(text.contains("2. Երաժշտություն"))
        XCTAssertTrue(text.contains("Անի"))
    }

    func testMergeKeepsOwnLessonsAndFillsFreeSlots() {
        let mine = Timetable(entries: [TimetableEntry(weekday: 2, period: 1, subject: "Ֆիզկուլտուրա")],
                             periods: [1: PeriodRange(start: 500, end: 545)])
        let merged = mine.merged(with: timetable)
        XCTAssertEqual(merged.entries.count, 2)
        XCTAssertEqual(merged.entries.first { $0.period == 1 }?.subject, "Ֆիզկուլտուրա")
        XCTAssertEqual(merged.entries.first { $0.period == 2 }?.subject, "Երաժշտություն")
        XCTAssertEqual(merged.periods[1]?.start, 500)
    }
}
