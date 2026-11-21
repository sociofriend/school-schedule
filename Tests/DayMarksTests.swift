import XCTest
@testable import SchoolSchedule

final class DayMarksTests: XCTestCase {
    func testDetectsTests() {
        XCTAssertTrue(DayMarks.isTest("Մաթեմ ստուգողական"))
        XCTAssertTrue(DayMarks.isTest("Գրավոր աշխատանք"))
        XCTAssertTrue(DayMarks.isTest("English TEST"))
        XCTAssertFalse(DayMarks.isTest("Կարդալ 12-րդ էջը"))
    }

    func testAllDoneNeedsTasks() {
        XCTAssertFalse(DayMarks().allDone)
        XCTAssertTrue(DayMarks(doneHomework: 2).allDone)
        XCTAssertFalse(DayMarks(pendingHomework: 1, doneHomework: 2).allDone)
    }
}
