import SwiftUI
import WidgetKit

struct ScheduleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ScheduleWidget", provider: ScheduleProvider()) { entry in
            ScheduleWidgetView(entry: entry)
                .fontDesign(.rounded)
                .environment(\.locale, .armenian)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: [Color.accentColor.opacity(0.18), Color(.systemBackground)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                }
        }
        .configurationDisplayName("Դասացուցակ")
        .description("Այսօրվա դասերը, իսկ դասերից հետո՝ վաղվա դասերն ու անելիքները։")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
    }
}

struct ScheduleWidgetView: View {
    let entry: ScheduleEntry
    @Environment(\.widgetFamily) private var family

    private var title: String {
        let name = Weekday.name(Calendar.current.component(.weekday, from: entry.snapshot.date))
        return entry.isToday ? "☀️ Այսօր · \(name)" : "🌙 Վաղը · \(name)"
    }

    var body: some View {
        if !entry.hasTimetable {
            Label("Սկանավորիր դասացուցակը", systemImage: "camera.viewfinder")
                .font(.caption)
        } else {
            switch family {
            case .accessoryRectangular: rectangular
            case .systemMedium: medium
            case .systemLarge: large
            default: small
            }
        }
    }

    private typealias Featured = (lesson: LessonSlot, label: String, until: Date?)

    /// The lesson to feature now, its label and the moment its countdown runs to.
    private var featured: Featured? {
        switch entry.phase {
        case let .inLesson(lesson, _): return (lesson: lesson, label: "Հիմա", until: lesson.end)
        case let .onBreak(next): return (lesson: next, label: "Դասամիջոց · հետո", until: next.start)
        case let .beforeSchool(first): return (lesson: first, label: "Առաջին դասը", until: first.start)
        case .finished, nil:
            guard let first = entry.snapshot.lessons.first else { return nil }
            return (lesson: first, label: entry.isToday ? "Առաջին դասը" : "Վաղը առաջինը", until: nil)
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading) {
            if let featured {
                Text(featured.label).font(.caption2).widgetAccentable()
                Text(featured.lesson.subject).font(.headline).lineLimit(1)
                countdown(featured).font(.caption)
            } else {
                Text(title).font(.caption2).widgetAccentable()
            }
        }
    }

    @ViewBuilder private func countdown(_ featured: Featured) -> some View {
        if let until = featured.until, until > entry.date {
            Text(timerInterval: entry.date...until, countsDown: true).monospacedDigit()
        } else if let start = featured.lesson.start {
            Text(start.armenianTime())
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let featured {
                HStack(spacing: 6) {
                    SubjectIcon(subject: featured.lesson.subject, size: 28).widgetAccentable()
                    Text(featured.label).font(.caption2.weight(.bold)).foregroundStyle(.secondary).lineLimit(1)
                }
                Text(featured.lesson.subject).font(.headline).lineLimit(2).minimumScaleFactor(0.8)
                countdown(featured).font(.caption.weight(.semibold)).foregroundStyle(.tint)
                Spacer(minLength: 0)
                let rest = entry.snapshot.lessons.filter { $0.period > featured.lesson.period }.prefix(2)
                ForEach(rest) { lesson in
                    Text("\(lesson.period). \(lesson.subject)").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            } else {
                header
                lessons(limit: 5)
                Spacer(minLength: 0)
            }
        }
    }

    private var medium: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                header
                lessons(limit: 5)
                Spacer(minLength: 0)
            }
            Divider()
            tasks(limit: 5)
        }
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            lessons(limit: 8)
            Divider()
            tasks(limit: 6)
            Spacer(minLength: 0)
        }
    }

    private var header: some View {
        Text(title).font(.caption.weight(.semibold)).foregroundStyle(.tint)
    }

    private func lessons(limit: Int) -> some View {
        ForEach(entry.snapshot.lessons.prefix(limit)) { lesson in
            let isCurrent = lesson.period == entry.currentPeriod
            HStack(spacing: 4) {
                Image(systemName: SubjectStyle(subject: lesson.subject).symbol)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(SubjectStyle(subject: lesson.subject).color)
                    .frame(width: 16)
                    .widgetAccentable()
                Text(lesson.subject).font(.caption.weight(isCurrent ? .bold : .regular)).lineLimit(1)
                Spacer(minLength: 0)
                if family != .systemSmall, let start = lesson.start {
                    Text(start.armenianTime()).font(.caption2).foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(isCurrent ? AnyShapeStyle(TintShapeStyle()) : AnyShapeStyle(HierarchicalShapeStyle.primary))
        }
    }

    private func tasks(limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            let remaining = entry.snapshot.remainingTasks
            Text(remaining.isEmpty ? "Ամեն ինչ արված է ⭐️" : "Անելիքներ · \(remaining.count)")
                .font(.caption.weight(.semibold))
            ForEach(remaining.prefix(limit)) { task in
                Label(task.title, systemImage: "circle").font(.caption2).lineLimit(1)
                    .foregroundStyle(task.subject.isEmpty ? Color.primary : SubjectStyle(subject: task.subject).color)
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview(as: .systemMedium) {
    ScheduleWidget()
} timeline: {
    ScheduleEntry.placeholder
}
