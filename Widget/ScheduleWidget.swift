import SwiftUI
import WidgetKit

struct ScheduleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ScheduleWidget", provider: ScheduleProvider()) { entry in
            ScheduleWidgetView(entry: entry)
                .fontDesign(.rounded)
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

    private var rectangular: some View {
        let lesson = entry.snapshot.lessons.first { $0.period == entry.currentPeriod } ?? entry.snapshot.lessons.first
        return VStack(alignment: .leading) {
            Text(title).font(.caption2).widgetAccentable()
            if let lesson {
                Text("\(lesson.period). \(lesson.subject)").font(.headline).lineLimit(1)
                if let start = lesson.start { Text(start, style: .time).font(.caption) }
            }
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            lessons(limit: 5)
            Spacer(minLength: 0)
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
                    Text(start, style: .time).font(.caption2).foregroundStyle(.secondary)
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
