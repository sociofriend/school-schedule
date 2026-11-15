import Combine
import Foundation
import OSLog
import UserNotifications

/// Schedules the evening "tomorrow's schedule + homework" notification.
/// Content is computed ahead for the next two weeks and rebuilt whenever data or settings change.
@MainActor
final class NotificationScheduler: NSObject {
    private let store: DataStore
    private let center = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Dasacucak", category: "Notifications")
    private var cancellables = Set<AnyCancellable>()
    private static let idPrefix = "evening-"
    private static let daysAhead = 14

    init(store: DataStore) {
        self.store = store
        super.init()
        center.delegate = self
    }

    func start() {
        store.changes
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.rescheduleInBackground() }
            .store(in: &cancellables)
        rescheduleInBackground()
    }

    func requestAuthorization() async -> Bool {
        do { return try await center.requestAuthorization(options: [.alert, .sound, .badge]) } catch {
            logger.error("Authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    func rescheduleInBackground() {
        Task { await reschedule() }
    }

    func reschedule(now: Date = .now) async {
        let pending = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(Self.idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)

        let settings = ReminderSettings.load()
        guard settings.isEnabled else { return }
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        let calendar = store.calendar
        let today = calendar.startOfDay(for: now)
        for offset in 0..<Self.daysAhead {
            guard let eveningDay = calendar.date(byAdding: .day, value: offset, to: today),
                  let targetDay = calendar.date(byAdding: .day, value: 1, to: eveningDay) else { continue }
            let fireDate = eveningDay.adding(minutes: settings.minuteOfDay, calendar: calendar)
            guard fireDate > now else { continue }

            let snapshot = store.snapshot(for: targetDay)
            guard !snapshot.isEmpty else { continue }

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let request = UNNotificationRequest(
                identifier: Self.idPrefix + ISO8601DateFormatter().string(from: targetDay),
                content: Self.content(for: snapshot),
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
            do { try await center.add(request) } catch {
                logger.error("Add failed: \(error.localizedDescription)")
            }
        }
    }

    static func content(for snapshot: DaySnapshot) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Վաղը՝ \(Weekday.name(Calendar.current.component(.weekday, from: snapshot.date)))"
        var lines = snapshot.lessons.map { lesson in
            let time = lesson.start.map { " · \($0.formatted(date: .omitted, time: .shortened))" } ?? ""
            return "\(lesson.period). \(lesson.subject)\(time)"
        }
        let remaining = snapshot.remainingTasks
        if !remaining.isEmpty {
            lines.append("Անելիքներ՝ \(remaining.count)")
            lines += remaining.map { "☐ \($0.subject.isEmpty ? "" : "\($0.subject)․ ")\($0.title)" }
        }
        content.body = lines.joined(separator: "\n")
        content.sound = .default
        content.threadIdentifier = "evening"
        return content
    }
}

extension NotificationScheduler: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
