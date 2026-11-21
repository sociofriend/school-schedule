import SwiftUI

/// Hero card: what is happening right now (lesson, break, before school) with live countdowns,
/// or the first lesson of the next school day. A row of beads shows how far through the day the kid is.
struct NowCard: View {
    let phase: DayPhase?
    let lessons: [LessonSlot]
    let lessonsDone: Int
    let isToday: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
            if !lessons.isEmpty { beads }
        }
        .foregroundStyle(.white)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.gradient, in: .rect(cornerRadius: 26, style: .continuous))
        .shadow(color: tint.opacity(0.35), radius: 12, y: 6)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var content: some View {
        switch phase {
        case let .inLesson(lesson, next):
            row(lesson, badge: "Հիմա") {
                if let start = lesson.start, let end = lesson.end {
                    ProgressView(timerInterval: start...end, countsDown: false) {
                        EmptyView()
                    } currentValueLabel: {
                        HStack(spacing: 4) {
                            Text("Ավարտին՝")
                            Text(timerInterval: Date.now...max(end, .now), countsDown: true).monospacedDigit()
                        }
                    }
                    .tint(.white)
                }
                if let next { Text("Հետո՝ \(next.subject)").font(.subheadline.weight(.semibold)).opacity(0.9) }
            }
        case let .onBreak(next):
            row(next, badge: "Դասամիջոց 🍎") { countdown(to: next.start, prefix: "Կսկսվի") }
        case let .beforeSchool(first):
            row(first, badge: "Առաջին դասը") { countdown(to: first.start, prefix: "Մինչև դասը") }
        case .finished, nil:
            if let first = lessons.first {
                row(first, badge: isToday ? "Առաջին դասը" : "Վաղը առաջինը") {
                    Text("Ընդամենը՝ \(lessons.count) դաս").font(.subheadline.weight(.semibold)).opacity(0.9)
                }
            } else {
                Text("Դասեր չկան, ազատ օր է 🎉").font(.title2.bold())
            }
        }
    }

    private func row(_ lesson: LessonSlot, badge: String, @ViewBuilder detail: () -> some View) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: SubjectStyle(subject: lesson.subject).symbol)
                .font(.system(size: 30, weight: .bold))
                .frame(width: 64, height: 64)
                .background(.white.opacity(0.22), in: .rect(cornerRadius: 20, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(badge)
                    .font(.caption.weight(.heavy))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(.white.opacity(0.25), in: .capsule)
                Text(lesson.subject).font(.title2.bold()).lineLimit(2).minimumScaleFactor(0.8)
                HStack(spacing: 10) {
                    if let start = lesson.start { Label(start.armenianTime, systemImage: "clock") }
                    if !lesson.room.isEmpty { Label(lesson.room, systemImage: "door.left.hand.open") }
                }
                .font(.subheadline.weight(.medium)).opacity(0.9)
                detail()
            }
        }
    }

    @ViewBuilder private func countdown(to date: Date?, prefix: String) -> some View {
        if let date, date > .now {
            HStack(spacing: 4) {
                Text("\(prefix)՝")
                Text(timerInterval: Date.now...date, countsDown: true).monospacedDigit()
            }
            .font(.headline)
        }
    }

    /// One bead per lesson, filled once it has ended.
    private var beads: some View {
        HStack(spacing: 6) {
            ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                Capsule()
                    .fill(.white.opacity(index < lessonsDone ? 1 : 0.3))
                    .frame(height: 8)
            }
        }
        .animation(.spring, value: lessonsDone)
        .accessibilityLabel("Անցած դասեր՝ \(lessonsDone)՝ \(lessons.count)-ից")
    }

    private var tint: Color {
        switch phase {
        case let .inLesson(lesson, _): SubjectStyle(subject: lesson.subject).color
        case let .onBreak(next): SubjectStyle(subject: next.subject).color
        case let .beforeSchool(first): SubjectStyle(subject: first.subject).color
        case .finished, nil: lessons.first.map { SubjectStyle(subject: $0.subject).color } ?? .accentColor
        }
    }
}
