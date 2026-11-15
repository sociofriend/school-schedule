import Foundation
import SwiftData

/// Notes and photos (e.g. the blackboard) for one subject on one day.
@Model
final class LessonNote {
    /// Start of day.
    var day: Date
    var subject: String
    var text: String
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \NotePhoto.note)
    var photos: [NotePhoto] = []

    init(day: Date, subject: String, text: String = "") {
        self.day = day
        self.subject = subject
        self.text = text
        self.updatedAt = .now
    }

    var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && photos.isEmpty
    }
}

@Model
final class NotePhoto {
    @Attribute(.externalStorage) var imageData: Data
    var createdAt: Date
    var note: LessonNote?

    init(imageData: Data) {
        self.imageData = imageData
        self.createdAt = .now
    }
}
