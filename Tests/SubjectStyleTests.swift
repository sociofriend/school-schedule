import XCTest
@testable import SchoolSchedule

/// Tests for grade-aware SubjectStyle symbols.
final class SubjectStyleTests: XCTestCase {
    func testNoGradeKeepsDefaultSymbols() {
        XCTAssertEqual(SubjectStyle(subject: "Հանրահաշիվ", grade: nil).symbol, "function")
        XCTAssertEqual(SubjectStyle(subject: "Ֆիզիկա", grade: nil).symbol, "atom")
    }

    func testMathFollowsStage() {
        XCTAssertEqual(SubjectStyle(subject: "Մաթեմատիկա", grade: 2).symbol, "textformat.123")
        XCTAssertEqual(SubjectStyle(subject: "Մաթեմատիկա", grade: 5).symbol, "plus.forwardslash.minus")
        XCTAssertNotEqual(SubjectStyle(subject: "Հանրահաշիվ", grade: 7).symbol, "function")
        XCTAssertEqual(SubjectStyle(subject: "Հանրահաշիվ և մաթեմատիկական անալիզի տարրեր", grade: 11).symbol, "function")
        XCTAssertEqual(SubjectStyle(subject: "Երկրաչափություն", grade: 8).symbol, "triangle")
    }

    func testColorDoesNotDependOnGrade() {
        for subject in ArmenianCurriculum.allSubjects {
            XCTAssertEqual(SubjectStyle(subject: subject, grade: 1).color, SubjectStyle(subject: subject, grade: 12).color, subject)
        }
    }

    func testEveryCurriculumSubjectHasItsOwnRule() {
        for grade in ArmenianCurriculum.grades {
            for subject in ArmenianCurriculum.subjects(for: grade) {
                XCTAssertNotEqual(SubjectStyle(subject: subject, grade: grade).symbol, "book.closed.fill", "\(subject), grade \(grade)")
            }
        }
    }

    func testOutOfRangeGradeFallsBackToDefault() {
        XCTAssertEqual(SubjectStyle(subject: "Մաթեմատիկա", grade: 0).symbol, "function")
    }
}
