import Combine
import SwiftData
import WidgetKit

/// Composition root: builds shared services once.
@MainActor
final class AppEnvironment {
    let store: DataStore
    let notifications: NotificationScheduler
    private var cancellables = Set<AnyCancellable>()

    init(container: ModelContainer = SharedModelContainer.shared) {
        store = DataStore(container: container)
        store.seedDefaultPeriodsIfNeeded()
        notifications = NotificationScheduler(store: store)
        notifications.start()

        store.changes
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { WidgetCenter.shared.reloadAllTimelines() }
            .store(in: &cancellables)
    }
}
