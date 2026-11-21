import Foundation
import Observation

/// Edits the weekly timetable. Used for manual entry and for reviewing a scan.
@MainActor
@Observable
final class TimetableEditorViewModel {
    struct Row: Identifiable, Equatable {
        let id = UUID()
        var subject: String
        var room: String
    }

    /// Which lesson the subject picker fills: a new row, or an existing one.
    enum PickerTarget: Identifiable, Hashable {
        case newRow
        case row(UUID)
        var id: Self { self }
    }

    var weekday: Int = Weekday.schoolWeek[0]
    /// Rows per weekday; row index + 1 is the lesson number. Empty subject = free period.
    var days: [Int: [Row]] = [:]
    let isReviewingScan: Bool
    /// Kid's grade from the profile; picks which official subject list is suggested.
    let grade: Int?
    var pickerTarget: PickerTarget?

    private let store: DataStore
    private let scannedPeriods: [Int: PeriodRange]

    init(store: DataStore, scanned: ParsedTimetable? = nil, grade: Int? = ProfileStore().grade) {
        self.store = store
        self.grade = grade
        self.isReviewingScan = scanned != nil
        self.scannedPeriods = scanned?.periods ?? [:]
        let entries = scanned?.entries ?? store.timetable().entries
        days = Self.rows(from: entries)
        if let first = Weekday.schoolWeek.first(where: { !(days[$0]?.isEmpty ?? true) }) { weekday = first }
    }

    var rows: [Row] {
        get { days[weekday] ?? [] }
        set { days[weekday] = newValue }
    }

    var subjectSuggestions: [String] {
        Array(Set(days.values.flatMap { $0.map(\.subject) }.filter { !$0.isEmpty })).sorted()
    }

    /// Official subjects for the grade, or all grades' subjects when no grade is set.
    var curriculumSubjects: [String] {
        grade.map(ArmenianCurriculum.subjects(for:)) ?? ArmenianCurriculum.allSubjects
    }

    /// Subjects already in this timetable that the official list lacks (school component, clubs, tutoring).
    var ownSubjects: [String] {
        let official = Set(curriculumSubjects)
        return subjectSuggestions.filter { !official.contains($0) }
    }

    /// Case-insensitive substring filter for the picker's search field.
    nonisolated static func filter(_ subjects: [String], by query: String) -> [String] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return subjects }
        return subjects.filter { $0.localizedStandardContains(query) }
    }

    /// Puts the picked (or typed) subject into the picker's target; empty adds a free period.
    func choose(_ subject: String) {
        let subject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        switch pickerTarget {
        case .newRow: rows.append(Row(subject: subject, room: ""))
        case .row(let id): if let index = rows.firstIndex(where: { $0.id == id }) { rows[index].subject = subject }
        case nil: break
        }
        pickerTarget = nil
    }

    func addRow() { pickerTarget = .newRow }
    func delete(at offsets: IndexSet) { rows.remove(atOffsets: offsets) }
    func move(from source: IndexSet, to destination: Int) { rows.move(fromOffsets: source, toOffset: destination) }

    func save() {
        let entries = days.flatMap { weekday, rows in
            rows.enumerated().compactMap { index, row -> TimetableEntry? in
                let subject = row.subject.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !subject.isEmpty else { return nil }
                return TimetableEntry(weekday: weekday, period: index + 1, subject: subject,
                                      room: row.room.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        store.replaceTimetable(with: entries, periods: scannedPeriods)
    }

    private static func rows(from entries: [TimetableEntry]) -> [Int: [Row]] {
        Dictionary(grouping: entries, by: \.weekday).mapValues { dayEntries in
            let byPeriod = Dictionary(dayEntries.map { ($0.period, $0) }, uniquingKeysWith: { first, _ in first })
            let last = byPeriod.keys.max() ?? 0
            return (1...max(last, 1)).map { Row(subject: byPeriod[$0]?.subject ?? "", room: byPeriod[$0]?.room ?? "") }
        }
    }
}
