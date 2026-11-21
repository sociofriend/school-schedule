import XCTest
@testable import SchoolSchedule

/// Tests for ArmenianCurriculum and the timetable picker's filter.
final class ArmenianCurriculumTests: XCTestCase {
    func testEveryGradeHasSubjectsWithoutDuplicates() {
        for grade in ArmenianCurriculum.grades {
            let subjects = ArmenianCurriculum.subjects(for: grade)
            XCTAssertFalse(subjects.isEmpty, "grade \(grade)")
            XCTAssertEqual(Set(subjects).count, subjects.count, "duplicates in grade \(grade)")
            XCTAssertFalse(subjects.contains { $0.trimmingCharacters(in: .whitespaces).isEmpty }, "blank in grade \(grade)")
        }
    }

    func testOutOfRangeGradeIsEmpty() {
        XCTAssertTrue(ArmenianCurriculum.subjects(for: 0).isEmpty)
        XCTAssertTrue(ArmenianCurriculum.subjects(for: 13).isEmpty)
    }

    func testListSizesMatchStandard() {
        let counts = ArmenianCurriculum.grades.map { ArmenianCurriculum.subjects(for: $0).count }
        XCTAssertEqual(counts, [7, 11, 13, 13, 14, 16, 20, 20, 19, 18, 18, 18])
    }

    func testAllSubjectsIsUniqueUnion() {
        let all = ArmenianCurriculum.allSubjects
        XCTAssertEqual(Set(all).count, all.count)
        XCTAssertEqual(Set(all), Set(ArmenianCurriculum.grades.flatMap(ArmenianCurriculum.subjects(for:))))
    }

    func testGradeNames() {
        XCTAssertEqual(ArmenianCurriculum.gradeName(1), "1-ին դասարան")
        XCTAssertEqual(ArmenianCurriculum.gradeName(12), "12-րդ դասարան")
    }

    func testProfileGradeDefaultsToNilAndRoundTrips() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "ArmenianCurriculumTests"))
        defaults.removePersistentDomain(forName: "ArmenianCurriculumTests")
        let store = ProfileStore(defaults: defaults)
        XCTAssertNil(store.grade)
        store.grade = 7
        XCTAssertEqual(store.grade, 7)
        store.grade = nil
        XCTAssertNil(store.grade)
    }

    func testPickerFilterIgnoresCase() {
        let list = ArmenianCurriculum.subjects(for: 7)
        XCTAssertEqual(TimetableEditorViewModel.filter(list, by: "ֆԻԶ"), ["Ֆիզիկա", "Ֆիզկուլտուրա"])
        XCTAssertEqual(TimetableEditorViewModel.filter(list, by: "  "), list)
    }
}
