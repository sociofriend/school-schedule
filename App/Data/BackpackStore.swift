import Foundation

/// Backpack checklist storage in the App Group: the kid's own "always bring" items and per-day ticks.
struct BackpackStore {
    var defaults: UserDefaults = AppGroup.defaults
    var calendar: Calendar = .current

    private static let extrasKey = "backpack.extras"
    private static let packedKey = "backpack.packed"
    /// Ticks older than this are dropped on write.
    private static let keepDays = 14

    var extras: [String] {
        get { defaults.stringArray(forKey: Self.extrasKey) ?? [] }
        nonmutating set { defaults.set(newValue, forKey: Self.extrasKey) }
    }

    func packed(on day: Date) -> Set<String> {
        Set(packedByDay[key(day)] ?? [])
    }

    func setPacked(_ items: Set<String>, on day: Date) {
        let oldest = key(calendar.date(byAdding: .day, value: -Self.keepDays, to: .now) ?? .now)
        var all = packedByDay.filter { $0.key >= oldest }
        all[key(day)] = items.sorted()
        defaults.set(all, forKey: Self.packedKey)
    }

    private var packedByDay: [String: [String]] {
        defaults.dictionary(forKey: Self.packedKey) as? [String: [String]] ?? [:]
    }

    /// `yyyy-MM-dd`, sortable as text.
    private func key(_ day: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
