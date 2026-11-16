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

final class TesseractOutputTests: XCTestCase {
    func testSubjectDictionaryFixesTypicalTesseractErrors() {
        XCTAssertEqual(SubjectDictionary.correct("Շանրաճաշիվ"), "Հանրահաշիվ")
        XCTAssertEqual(SubjectDictionary.correct("ԸՇայաստանի պատմություն"), "Հայաստանի պատմություն")
        XCTAssertEqual(SubjectDictionary.correct("Ըալոց լեզու"), "Հայոց լեզու")
        XCTAssertEqual(SubjectDictionary.correct("Մաթեմատիկայի ճատուկ դասընթաց"), "Մաթեմատիկայի հատուկ դասընթաց")
        XCTAssertEqual(SubjectDictionary.correct("Ռոբոտաշինություն"), "Ռոբոտաշինություն") // unknown stays
    }

    func testTagVariantsFromOCR() {
        XCTAssertTrue(CardLine.isTag("Խմ -"))
        XCTAssertTrue(CardLine.isTag("ՆՈՒ · Փոքրիկ սերմի"))
        XCTAssertFalse(CardLine.isTag("Ֆիզ. դաստիարակություն"))
    }

    func testMissingHeaderIsInferredFromNeighbour() throws {
        // Two columns; only the first header ("ուրբ" = Friday) was read.
        func text(_ s: String, x: CGFloat, y: CGFloat) -> RecognizedText {
            RecognizedText(text: s, box: CGRect(x: x, y: y, width: 0.1, height: 0.015))
        }
        let items = [
            text("ուրբ", x: 0.05, y: 0.95),
            text("08:15 - 09:00", x: 0.02, y: 0.8), text("Քիմիա", x: 0.02, y: 0.78), text("Ներկա", x: 0.02, y: 0.76),
            text("09:05 - 09:50", x: 0.02, y: 0.7), text("Ֆիզիկա", x: 0.02, y: 0.68), text("Ներկա", x: 0.02, y: 0.66),
            text("08:15 - 09:00", x: 0.52, y: 0.8), text("Շախմատ", x: 0.52, y: 0.78), text("Ներկա", x: 0.52, y: 0.76),
        ]
        let entries = try TimetableParser().parse(items).entries
        XCTAssertEqual(Set(entries.map(\.weekday)), [6, 7])
    }
}

/// Armenian weekday forms and OCR look-alikes; word-level OCR grouped into a grid.
final class ArmenianTimetableTests: XCTestCase {
    private func word(_ string: String, x: CGFloat, y: CGFloat, w: CGFloat = 0.06) -> RecognizedText {
        RecognizedText(text: string, box: CGRect(x: x - w / 2, y: y - 0.01, width: w, height: 0.02))
    }

    func testWeekdayFormsAndVariants() {
        let expected: [String: Int] = [
            "Երկուշաբթի": 2, "Երեքշաբթի": 3, "Չորեքշաբթի": 4, "Հինգշաբթի": 5, "Ուրբաթ": 6, "Շաբաթ": 7, "Կիրակի": 1,
            "երկ.": 2, "երք.": 3, "երեք.": 3, "չորք.": 4, "չորեք.": 4, "հինգ.": 5, "ուրբ.": 6, "շաբ.": 7,
            "Երկ․": 2, "ՉՈՐ": 4, "Շաբաթ։": 7, "Երկուշաբթի 12.09": 2,
            "hինգշաբթի": 5, "nւրբաթ": 6, "ճինգշաբթի": 5, "Երկուշաբտի": 2, "ճինգ": 5,
        ]
        for (text, weekday) in expected {
            XCTAssertEqual(WeekdayMatcher.weekday(in: text), weekday, text)
        }
    }

    func testWeekdayDisambiguationAndSubjects() {
        XCTAssertEqual(WeekdayMatcher.weekday(in: "շաբաթ"), 7)      // not a …շաբթի
        XCTAssertEqual(WeekdayMatcher.weekday(in: "երկ"), 2)        // not երեք
        XCTAssertNil(WeekdayMatcher.weekday(in: "որեքշաբթի"))       // as close to երեք… as to չորեք…
        for subject in ["Երկրաչափություն", "Շախմատ", "Երգ", "Կերպարվեստ", "Հայոց լեզու", "Մաթեմատիկա"] {
            XCTAssertNil(WeekdayMatcher.weekday(in: subject), subject)
        }
    }

    func testSubjectCleanerDropsLabelsAndNoise() {
        XCTAssertEqual(SubjectCleaner.clean("1-ին"), "")
        XCTAssertEqual(SubjectCleaner.clean("2-րդ Քիմիա"), "Քիմիա")
        XCTAssertEqual(SubjectCleaner.clean("l"), "")
        XCTAssertEqual(SubjectCleaner.clean("Դաս"), "")
    }

    func testWordsGroupIntoCellsButHeaderRowSplits() {
        let cells = TextLayout.cells(from: [
            word("Երկ", x: 0.1, y: 0.9, w: 0.04), word("Երք", x: 0.16, y: 0.9, w: 0.04), word("Չոր", x: 0.22, y: 0.9, w: 0.04),
            word("1", x: 0.05, y: 0.8, w: 0.02), word("Հայոց", x: 0.09, y: 0.8, w: 0.05), word("լեզու", x: 0.145, y: 0.8, w: 0.04),
        ]).map(\.text)
        XCTAssertEqual(Set(cells), ["Երկ", "Երք", "Չոր", "1", "Հայոց լեզու"])
    }

    func testGridFromWordsWithMissingHeaderWrappedCellAndLabelColumn() throws {
        let items = [
            word("Երկ.", x: 0.3, y: 0.9, w: 0.05), word("Երք․", x: 0.45, y: 0.9, w: 0.05),
            word("Հնգ.", x: 0.75, y: 0.9, w: 0.05), word("Ուրբ.", x: 0.9, y: 0.9, w: 0.05), // Wednesday unread
            word("1-ին", x: 0.04, y: 0.8, w: 0.05), word("8:30-9:15", x: 0.12, y: 0.8, w: 0.07),
            word("Հայոց", x: 0.28, y: 0.8, w: 0.05), word("լեզու", x: 0.335, y: 0.8, w: 0.04),
            word("Ֆիզիկա", x: 0.6, y: 0.8, w: 0.07), word("Քիմիա", x: 0.9, y: 0.8),
            word("2-րդ", x: 0.04, y: 0.7, w: 0.05), word("9:25-10:10", x: 0.12, y: 0.7, w: 0.07),
            word("Մաթեմատիկա", x: 0.45, y: 0.7, w: 0.1), word("l", x: 0.53, y: 0.7, w: 0.005),
            word("Համաշխարհային", x: 0.75, y: 0.705, w: 0.1), word("պատմություն", x: 0.75, y: 0.685, w: 0.1),
            word("3", x: 0.04, y: 0.6, w: 0.02), word("Երկրաչափություն", x: 0.3, y: 0.6, w: 0.1),
        ]
        let result = try TimetableParser().parse(items)
        XCTAssertEqual(Set(result.entries), [
            TimetableEntry(weekday: 2, period: 1, subject: "Հայոց լեզու"),
            TimetableEntry(weekday: 4, period: 1, subject: "Ֆիզիկա"),
            TimetableEntry(weekday: 6, period: 1, subject: "Քիմիա"),
            TimetableEntry(weekday: 3, period: 2, subject: "Մաթեմատիկա"),
            TimetableEntry(weekday: 5, period: 2, subject: "Համաշխարհային պատմություն"),
            TimetableEntry(weekday: 2, period: 3, subject: "Երկրաչափություն"),
        ])
        XCTAssertEqual(result.periods[1], PeriodRange(start: 510, end: 555))
        XCTAssertEqual(result.periods[2], PeriodRange(start: 565, end: 610))
    }

    func testDaysAsRowsWithFullNamesAndLookAlikes() throws {
        let items = [
            word("ԵՐԿՈՒՇԱԲԹԻ", x: 0.1, y: 0.8, w: 0.1), word("Մաթեմատիկա", x: 0.3, y: 0.8, w: 0.1), word("Արվեստ", x: 0.5, y: 0.8),
            word("nւրբաթ", x: 0.1, y: 0.6, w: 0.1), word("Քիմիա", x: 0.3, y: 0.6),
        ]
        XCTAssertEqual(Set(try TimetableParser().parse(items).entries), [
            TimetableEntry(weekday: 2, period: 1, subject: "Մաթեմատիկա"),
            TimetableEntry(weekday: 2, period: 2, subject: "Արվեստ"),
            TimetableEntry(weekday: 6, period: 1, subject: "Քիմիա"),
        ])
    }
}
