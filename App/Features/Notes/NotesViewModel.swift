import Combine
import Foundation
import Observation

@MainActor
@Observable
final class NotesViewModel {
    struct DayGroup: Identifiable {
        var id: Date { day }
        let day: Date
        let notes: [LessonNote]
    }

    var searchText = "" {
        didSet { searchChanges.send(searchText) }
    }
    var subjectFilter: String? {
        didSet { apply() }
    }
    private(set) var groups: [DayGroup] = []
    private(set) var subjects: [String] = []
    /// Subjects from the timetable, for the new-note picker.
    private(set) var timetableSubjects: [String] = []

    // Draft for the new-note sheet.
    var draftSubject = ""
    var draftDay: Date = .now

    private let store: DataStore
    private var allNotes: [LessonNote] = []
    @ObservationIgnored private let searchChanges = PassthroughSubject<String, Never>()
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    init(store: DataStore) {
        self.store = store
        store.changes
            .sink { [weak self] in self?.reload() }
            .store(in: &cancellables)
        searchChanges
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in self?.apply() }
            .store(in: &cancellables)
        reload()
    }

    func reload() {
        allNotes = store.allNotes()
        timetableSubjects = store.timetable().subjects
        subjects = Array(Set(allNotes.map(\.subject))).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        apply()
    }

    /// Defaults to the lesson running now or next today, or today's last lesson after school (when notes get written).
    func prepareDraft(now: Date = .now) {
        let calendar = store.calendar
        let today = store.timetable().slots(on: now, calendar: calendar)
        let lesson = today.first { ($0.end ?? .distantPast) > now } ?? today.last
        draftSubject = lesson?.subject ?? timetableSubjects.first ?? ""
        draftDay = now
    }

    var draftRoute: LessonRoute? {
        let subject = draftSubject.trimmingCharacters(in: .whitespacesAndNewlines)
        return subject.isEmpty ? nil : LessonRoute(day: store.calendar.startOfDay(for: draftDay), subject: subject)
    }

    private func apply() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        let filtered = allNotes.filter { note in
            (subjectFilter == nil || note.subject == subjectFilter)
                && (query.isEmpty || note.subject.localizedStandardContains(query) || note.text.localizedStandardContains(query))
        }
        groups = Dictionary(grouping: filtered, by: \.day)
            .map { DayGroup(day: $0.key, notes: $0.value.sorted { $0.subject < $1.subject }) }
            .sorted { $0.day > $1.day }
    }
}
