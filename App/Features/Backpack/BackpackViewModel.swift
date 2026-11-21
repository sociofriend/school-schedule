import Foundation
import Observation

/// Backpack checklist for one school day: a book per subject plus the kid's own items.
@MainActor
@Observable
final class BackpackViewModel {
    struct Item: Identifiable, Hashable {
        var id: String { title }
        let title: String
        /// Set for subject books; `nil` for the kid's own items.
        let subject: String?
        let isPacked: Bool
    }

    private(set) var day: Date = .now
    private(set) var items: [Item] = []
    /// Increments when the last item gets packed.
    private(set) var celebrations = 0
    var newExtra = ""

    private let storage: BackpackStore
    @ObservationIgnored private var subjects: [String] = []

    init(storage: BackpackStore = BackpackStore()) {
        self.storage = storage
    }

    var packedCount: Int { items.filter(\.isPacked).count }
    var isComplete: Bool { !items.isEmpty && packedCount == items.count }
    var progress: Double { items.isEmpty ? 0 : Double(packedCount) / Double(items.count) }

    /// Called by Today whenever its focus day or lessons change.
    func update(day: Date, lessons: [LessonSlot]) {
        self.day = day
        var seen = Set<String>()
        subjects = lessons.map(\.subject).filter { seen.insert($0).inserted }
        rebuild()
    }

    func toggle(_ item: Item) {
        var packed = storage.packed(on: day)
        if packed.remove(item.id) == nil { packed.insert(item.id) }
        storage.setPacked(packed, on: day)
        let wasComplete = isComplete
        rebuild()
        if !wasComplete, isComplete { celebrations += 1 }
    }

    func addExtra() {
        let title = newExtra.trimmingCharacters(in: .whitespacesAndNewlines)
        newExtra = ""
        guard !title.isEmpty, !storage.extras.contains(title), !subjects.contains(title) else { return }
        storage.extras.append(title)
        rebuild()
    }

    func removeExtra(_ item: Item) {
        storage.extras.removeAll { $0 == item.title }
        rebuild()
    }

    private func rebuild() {
        let packed = storage.packed(on: day)
        items = subjects.map { Item(title: $0, subject: $0, isPacked: packed.contains($0)) }
            + storage.extras.map { Item(title: $0, subject: nil, isPacked: packed.contains($0)) }
    }
}
