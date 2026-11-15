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

    var weekday: Int = Weekday.schoolWeek[0]
    /// Rows per weekday; row index + 1 is the lesson number. Empty subject = free period.
    var days: [Int: [Row]] = [:]
    let isReviewingScan: Bool

    private let store: DataStore
    private let scannedPeriods: [Int: PeriodRange]

    init(store: DataStore, scanned: ParsedTimetable? = nil) {
        self.store = store
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

    func addRow() { rows.append(Row(subject: "", room: "")) }
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
