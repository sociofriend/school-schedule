import SwiftUI

/// Lesson row reused by Today, Calendar and Notes: colored subject icon first, so it reads before text.
struct LessonRow: View {
    let lesson: LessonSlot
    var isCurrent = false
    var hasNote = false

    var body: some View {
        HStack(spacing: 14) {
            SubjectIcon(subject: lesson.subject, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(lesson.subject).font(.headline)
                    if isCurrent {
                        Text("Հիմա")
                            .font(.caption2.weight(.heavy))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(SubjectStyle(subject: lesson.subject).color, in: .capsule)
                            .foregroundStyle(.white)
                    }
                }
                HStack(spacing: 8) {
                    Text("\(lesson.period)-րդ դաս")
                    if let start = lesson.start {
                        Label(start.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                    }
                    if !lesson.room.isEmpty { Label(lesson.room, systemImage: "door.left.hand.open") }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)
            }
            Spacer(minLength: 0)
            if hasNote {
                Image(systemName: "note.text")
                    .foregroundStyle(SubjectStyle(subject: lesson.subject).color)
                    .accessibilityLabel("Կա գրառում")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

/// Big, tappable checklist row with a bouncy check.
struct TaskRow: View {
    let title: String
    let subject: String
    let isDone: Bool
    var dueText: String?
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(isDone ? Color.green : tint.opacity(0.6), lineWidth: 3)
                        .background(Circle().fill(isDone ? Color.green : .clear))
                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 30, height: 30)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isDone)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .strikethrough(isDone, color: .secondary)
                        .foregroundStyle(isDone ? .secondary : .primary)
                    let caption = [subject, dueText ?? ""].filter { !$0.isEmpty }.joined(separator: " · ")
                    if !caption.isEmpty { Text(caption).font(.caption).foregroundStyle(.secondary) }
                }
                Spacer(minLength: 0)
                if isDone { Text("⭐️").transition(.scale) }
            }
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(BouncyButtonStyle())
        .sensoryFeedback(.success, trigger: isDone) { _, done in done }
        .accessibilityLabel(title)
        .accessibilityValue(isDone ? "Կատարված է" : "Չկատարված")
        .accessibilityHint("Կրկնակի հպիր՝ նշելու համար")
    }

    private var tint: Color { subject.isEmpty ? .accentColor : SubjectStyle(subject: subject).color }
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
