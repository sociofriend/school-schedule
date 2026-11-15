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
        subjects = Array(Set(allNotes.map(\.subject))).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        apply()
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
