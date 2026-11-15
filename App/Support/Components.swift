import SwiftUI

/// Lesson row reused by Today, Calendar and the widget-like lists.
struct LessonRow: View {
    let lesson: LessonSlot
    var isCurrent = false
    var hasNote = false

    var body: some View {
        HStack(spacing: 12) {
            Text("\(lesson.period)")
                .font(.headline.monospacedDigit())
                .frame(width: 28, height: 28)
                .background(isCurrent ? Color.accentColor : Color.secondary.opacity(0.15), in: .circle)
                .foregroundStyle(isCurrent ? .white : .primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(lesson.subject).font(.body.weight(isCurrent ? .semibold : .regular))
                if let start = lesson.start, let end = lesson.end {
                    Text("\(start.formatted(date: .omitted, time: .shortened))–\(end.formatted(date: .omitted, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if hasNote { Image(systemName: "note.text").foregroundStyle(.secondary).accessibilityLabel("Կա գրառում") }
            if !lesson.room.isEmpty { Text(lesson.room).font(.caption).foregroundStyle(.secondary) }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Checklist row with a toggle button.
struct TaskRow: View {
    let title: String
    let subject: String
    let isDone: Bool
    var dueText: String?
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 12) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isDone ? Color.green : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).strikethrough(isDone).foregroundStyle(isDone ? .secondary : .primary)
                    let caption = [subject, dueText ?? ""].filter { !$0.isEmpty }.joined(separator: " · ")
                    if !caption.isEmpty { Text(caption).font(.caption).foregroundStyle(.secondary) }
                }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: isDone) { _, done in done }
        .accessibilityAddTraits(isDone ? .isSelected : [])
    }
}

/// Thumbnail decoded off the main thread.
struct PhotoThumbnail: View {
    let data: Data
    var maxPixelSize = 400
    var contentMode: ContentMode = .fill
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().aspectRatio(contentMode: contentMode)
            } else {
                Rectangle().fill(.quaternary)
            }
        }
        .task(id: data) {
            let data = data, size = maxPixelSize
            image = await Task.detached(priority: .utility) { ImageTools.thumbnail(from: data, maxPixelSize: size) }.value
        }
    }
}
