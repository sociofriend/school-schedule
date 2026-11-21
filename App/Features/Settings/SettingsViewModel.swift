import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class SettingsViewModel {
    struct PeriodDraft: Identifiable {
        var id: Int { period }
        let period: Int
        var start: Date
        var end: Date
    }

    var reminderEnabled: Bool {
        didSet { reminderChanged(requestingPermission: reminderEnabled && !oldValue) }
    }
    var reminderTime: Date {
        didSet { reminderChanged(requestingPermission: false) }
    }
    private(set) var notificationsDenied = false
    var periods: [PeriodDraft] = []

    private let store: DataStore
    private let notifications: NotificationScheduler
    private var reference: Date { store.calendar.startOfDay(for: .now) }

    init(store: DataStore, notifications: NotificationScheduler) {
        self.store = store
        self.notifications = notifications
        let settings = ReminderSettings.load()
        reminderEnabled = settings.isEnabled
        reminderTime = store.calendar.startOfDay(for: .now).adding(minutes: settings.minuteOfDay, calendar: store.calendar)
        loadPeriods()
    }

    func onAppear() async {
        if reminderEnabled { _ = await notifications.requestAuthorization() }
        notificationsDenied = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .denied
    }

    private func reminderChanged(requestingPermission: Bool) {
        let components = store.calendar.dateComponents([.hour, .minute], from: reminderTime)
        ReminderSettings(isEnabled: reminderEnabled,
                         minuteOfDay: (components.hour ?? 20) * 60 + (components.minute ?? 0)).save()
        Task {
            if requestingPermission { _ = await notifications.requestAuthorization() }
            await notifications.reschedule()
        }
    }

    // MARK: Bell schedule

    /// The kid's timetable to send to a friend; `nil` until there is one.
    var shareableTimetable: Timetable? {
        let timetable = store.timetable()
        return timetable.isEmpty ? nil : timetable
    }

    func loadPeriods() {
        periods = store.periodTimes().map {
            PeriodDraft(period: $0.period,
                        start: reference.adding(minutes: $0.startMinute, calendar: store.calendar),
                        end: reference.adding(minutes: $0.endMinute, calendar: store.calendar))
        }
    }

    func savePeriods() {
        let ranges = periods.map { draft in (draft.period, PeriodRange(start: minutes(draft.start), end: minutes(draft.end))) }
        store.setPeriods(Dictionary(ranges, uniquingKeysWith: { first, _ in first }))
    }

    func addPeriod() {
        let last = periods.last
        let start = last?.end.adding(minutes: 10, calendar: store.calendar) ?? reference.adding(minutes: 9 * 60)
        periods.append(PeriodDraft(period: (last?.period ?? 0) + 1, start: start, end: start.adding(minutes: 45)))
        savePeriods()
    }

    func removeLastPeriod() {
        guard let last = periods.popLast(),
              let model = store.periodTimes().first(where: { $0.period == last.period }) else { return }
        store.deletePeriod(model)
    }

    private func minutes(_ date: Date) -> Int {
        let c = store.calendar.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}
