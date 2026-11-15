import Foundation
import SwiftData

enum SharedModelContainer {
    static let schema = Schema([
        Lesson.self, PeriodTime.self, LessonNote.self, NotePhoto.self, TaskItem.self,
    ])

    /// One container per process, stored in the App Group so the widget reads the same data.
    static let shared: ModelContainer = {
        do {
            return try make()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            groupContainer: inMemory ? .none : .identifier(AppGroup.identifier)
        )
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
