import Combine
import Foundation
import Observation

@MainActor
@Observable
final class CalendarViewModel {
    var selectedDate: Date = .now {
        didSet { reloadDay() }
    }
    private(set) var snapshot: DaySnapshot = .empty(.now)
    private(set) var markedDays: Set<DateComponents> = []
    private(set) var subjectsWithNotes: Set<String> = []

    private let store: DataStore
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    init(store: DataStore) {
        self.store = store
        store.changes
            .sink { [weak self] in self?.reload() }
            .store(in: &cancellables)
        reload()
    }

    func reload() {
        markedDays = store.markedDays()
        reloadDay()
    }

    private func reloadDay() {
        snapshot = store.snapshot(for: selectedDate)
        subjectsWithNotes = Set(store.notes(on: selectedDate).map(\.subject))
    }

    func toggle(_ task: TaskSummary) { store.toggleTask(task.id) }
}
