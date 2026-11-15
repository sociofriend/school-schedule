import CoreGraphics
import XCTest
@testable import SchoolSchedule

final class TimetableParserTests: XCTestCase {
    private func text(_ string: String, x: CGFloat, y: CGFloat) -> RecognizedText {
        RecognizedText(text: string, box: CGRect(x: x - 0.05, y: y - 0.01, width: 0.1, height: 0.02))
    }

    func testDaysAsColumns() throws {
        let items = [
            text("Երկուշաբթի", x: 0.3, y: 0.9), text("Երեքշաբթի", x: 0.6, y: 0.9),
            text("1  9:00-9:45", x: 0.08, y: 0.8), text("Մաթեմատիկա", x: 0.3, y: 0.8), text("Ֆիզիկա", x: 0.6, y: 0.8),
            text("2  9:55-10:40", x: 0.08, y: 0.7), text("Անգլերեն", x: 0.6, y: 0.7),
            text("3", x: 0.08, y: 0.6), text("Պատմություն", x: 0.3, y: 0.6),
        ]
        let result = try TimetableParser().parse(items)
        XCTAssertEqual(Set(result.entries), [
            TimetableEntry(weekday: 2, period: 1, subject: "Մաթեմատիկա"),
            TimetableEntry(weekday: 3, period: 1, subject: "Ֆիզիկա"),
            TimetableEntry(weekday: 3, period: 2, subject: "Անգլերեն"),
            TimetableEntry(weekday: 2, period: 3, subject: "Պատմություն"),
        ])
        XCTAssertEqual(result.periods[1], PeriodRange(start: 540, end: 585))
        XCTAssertEqual(result.periods[2], PeriodRange(start: 595, end: 640))
    }

    func testDaysAsRows() throws {
        let items = [
            text("Mon", x: 0.1, y: 0.8), text("Math", x: 0.3, y: 0.8), text("Art", x: 0.5, y: 0.8),
            text("Tue", x: 0.1, y: 0.6), text("Music", x: 0.3, y: 0.6),
        ]
        let result = try TimetableParser().parse(items)
        XCTAssertEqual(Set(result.entries), [
            TimetableEntry(weekday: 2, period: 1, subject: "Math"),
            TimetableEntry(weekday: 2, period: 2, subject: "Art"),
            TimetableEntry(weekday: 3, period: 1, subject: "Music"),
        ])
    }

    func testNoWeekdaysThrows() {
        XCTAssertThrowsError(try TimetableParser().parse([text("Մաթեմատիկա", x: 0.5, y: 0.5)]))
    }

    func testWeekdayMatcher() {
        XCTAssertEqual(WeekdayMatcher.weekday(in: "ԵՐԿՈՒՇԱԲԹԻ"), 2)
        XCTAssertEqual(WeekdayMatcher.weekday(in: "Երք."), 3)
        XCTAssertEqual(WeekdayMatcher.weekday(in: "Шахматы"), nil)
        XCTAssertEqual(WeekdayMatcher.weekday(in: "Շախմատ"), nil)
    }

    func testSubjectCleaner() {
        XCTAssertEqual(SubjectCleaner.clean("2. Հայոց լեզու"), "Հայոց լեզու")
        XCTAssertEqual(SubjectCleaner.clean("10:50 - 11:35"), "")
    }
}

/// E-diary weekly view: columns of cards (time / subject / status), Armenian weekday abbreviations.
final class TimetableCardParserTests: XCTestCase {
    private let width: CGFloat = 2000, height: CGFloat = 1392

    private func text(_ string: String, left: CGFloat, top: CGFloat, width w: CGFloat = 200) -> RecognizedText {
        RecognizedText(text: string, box: CGRect(x: left / width, y: 1 - (top + 22) / height, width: w / width, height: 22 / height))
    }

    private func column(_ lines: [String], left: CGFloat) -> [RecognizedText] {
        lines.enumerated().map { text($1, left: left, top: 258 + CGFloat($0) * 32, width: $1.count < 8 ? 120 : 220) }
    }

    private var items: [RecognizedText] {
        let headers = zip(["երկ", "երք", "չոր", "հնգ", "ուրբ", "շաբ", "կիր"], [159, 436, 712, 989, 1266, 1542, 1819] as [CGFloat])
            .map { text($0, left: $1 - 20, top: 47, width: 40) }
        return headers + [text("9", left: 66, top: 129, width: 20), text("8 դաս", left: 40, top: 195, width: 60)]
            + column(["08:15 – 09:00", "Մաթեմատիկայի", "հատուկ դասընթաց", "Ներկա",
                      "09:05 – 09:50", "Ֆիզկուլտուրա", "Ներկա",
                      "14:30 – 15:15", "Ֆրանսերեն", "Ներկա",
                      "14:30 – 15:15", "ԽՄ ·", "առողջ ապրելակերպ", "Ներկա"], left: 53)
            + column(["08:15 – 09:00", "Հանրահաշիվ", "Ներկա",
                      "12:50 – 13:35", "ՆՈՒ ·", "Փոքրիկ սերմի", "Ներկա",
                      "12:50 – 13:35", "Կենսաբանություն", "Ներկա · 4"], left: 884)
            + column(["08:15 – 09:00", "Երկրաչափություն", "Ներկա"], left: 1160)
    }

    func testCardsWithHeaders() throws {
        let result = try TimetableParser().parse(items)
        XCTAssertEqual(Set(result.entries), [
            TimetableEntry(weekday: 2, period: 1, subject: "Մաթեմատիկայի հատուկ դասընթաց"),
            TimetableEntry(weekday: 2, period: 2, subject: "Ֆիզկուլտուրա"),
            TimetableEntry(weekday: 2, period: 4, subject: "Ֆրանսերեն"),
            TimetableEntry(weekday: 5, period: 1, subject: "Հանրահաշիվ"),
            TimetableEntry(weekday: 5, period: 3, subject: "Կենսաբանություն"),
            TimetableEntry(weekday: 6, period: 1, subject: "Երկրաչափություն"),
        ])
        XCTAssertEqual(result.periods[1], PeriodRange(start: 495, end: 540))
    }

    func testCardsWithoutReadableHeadersAssumeMondayFirst() throws {
        let unreadable = items.filter { WeekdayMatcher.weekday(in: $0.text) == nil }
        let weekdays = Set(try TimetableParser().parse(unreadable).entries.map(\.weekday))
        XCTAssertEqual(weekdays, [2, 3, 4])
    }

    func testCardLines() {
        XCTAssertTrue(CardLine.isTag("ԽՄ ·"))
        XCTAssertFalse(CardLine.isTag("Ֆիզ. դաստիարակություն"))
        XCTAssertTrue(CardLine.isStatus("Ներկա · 4"))
    }
}
