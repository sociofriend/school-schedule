import Combine
import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class LessonDetailViewModel {
    let route: LessonRoute
    var noteText: String {
        didSet { textChanges.send(noteText) }
    }
    private(set) var photos: [NotePhoto] = []
    private(set) var tasks: [TaskItem] = []
    var newTaskTitle = ""
    var newTaskDue: Date

    private let store: DataStore
    private let note: LessonNote
    @ObservationIgnored private let textChanges = PassthroughSubject<String, Never>()
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    init(store: DataStore, route: LessonRoute) {
        self.store = store
        self.route = route
        let note = store.noteCreatingIfNeeded(on: route.day, subject: route.subject)
        self.note = note
        self.noteText = note.text
        self.newTaskDue = store.timetable().nextOccurrence(of: route.subject, after: route.day, calendar: store.calendar)
            ?? store.calendar.date(byAdding: .day, value: 1, to: route.day) ?? route.day

        textChanges
            .debounce(for: .milliseconds(600), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] in self?.persist(text: $0) }
            .store(in: &cancellables)
        reload()
    }

    var title: String { route.subject }
    var dateText: String { route.day.armenianLongDay }

    func reload() {
        photos = note.photos.sorted { $0.createdAt < $1.createdAt }
        tasks = store.tasks(subject: route.subject, around: route.day)
    }

    func addPhotos(_ images: [UIImage]) {
        for image in images {
            guard let data = ImageTools.jpegData(from: image) else { continue }
            store.addPhoto(data, to: note)
        }
        reload()
    }

    func addPhotoData(_ data: Data) {
        guard let image = UIImage(data: data) else { return }
        addPhotos([image])
    }

    func delete(_ photo: NotePhoto) {
        store.deletePhoto(photo)
        reload()
    }

    func addTask() {
        guard store.addTask(title: newTaskTitle, subject: route.subject, due: newTaskDue, assignedOn: route.day) != nil else { return }
        newTaskTitle = ""
        reload()
    }

    func toggle(_ task: TaskItem) {
        store.toggle(task)
        reload()
    }

    func delete(_ task: TaskItem) {
        store.delete(task)
        reload()
    }

    /// Call on disappear: flushes pending text and drops an empty note.
    func finish() {
        persist(text: noteText)
        store.pruneIfEmpty(note)
    }

    private func persist(text: String) {
        guard note.modelContext != nil, note.text != text else { return }
        note.text = text
        note.updatedAt = .now
        store.save()
    }
}
