import SwiftUI

/// Compact month grid (or one week, when collapsed) with markers for homework, notes, photos and tests.
struct MonthCalendarView: View {
    @Binding var selection: Date
    let marks: [Date: DayMarks]
    /// Weekdays with lessons; the rest are dimmed.
    let schoolWeekdays: Set<Int>

    @Environment(\.theme) private var theme
    @AppStorage("calendar.weekMode") private var weekMode = false
    @State private var anchor = Date.now

    private let calendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday, as in Armenian schools
        return calendar
    }()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(spacing: 6) {
            header
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Self.weekOrder, id: \.self) { weekday in
                    Text(Weekday.shortName(weekday))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day { cell(day) } else { Color.clear.frame(height: 1) }
                }
            }
            .contentShape(.rect)
            .gesture(DragGesture(minimumDistance: 24).onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                step(value.translation.width < 0 ? 1 : -1)
            })
            if !weekMode { legend }
        }
        .animation(.snappy, value: weekMode)
        .animation(.snappy, value: anchor)
        .sensoryFeedback(.selection, trigger: selection)
        .onAppear { anchor = selection }
        .onChange(of: selection) { _, new in
            if !isShown(new) { anchor = new }
        }
    }

    // MARK: Parts

    private var header: some View {
        HStack(spacing: 16) {
            Text(anchor.formatted(.dateTime.month(.wide).year().locale(.armenian)).capitalized(with: .armenian))
                .font(.headline)
            Spacer()
            Button { step(-1) } label: { Image(systemName: "chevron.left") }
                .accessibilityLabel(weekMode ? "Նախորդ շաբաթ" : "Նախորդ ամիս")
            Button { step(1) } label: { Image(systemName: "chevron.right") }
                .accessibilityLabel(weekMode ? "Հաջորդ շաբաթ" : "Հաջորդ ամիս")
            Button {
                anchor = selection
                weekMode.toggle()
            } label: {
                Text(weekMode ? "Ամիս" : "Շաբաթ")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(theme.accent.opacity(0.14), in: .capsule)
            }
            .accessibilityLabel(weekMode ? "Ցույց տալ ամիսը" : "Ցույց տալ շաբաթը")
        }
        .buttonStyle(.borderless)
        .font(.body.weight(.semibold))
        .foregroundStyle(theme.accent)
        .padding(.horizontal, 4)
    }

    private func cell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selection)
        let isToday = calendar.isDateInToday(day)
        let mark = marks[calendar.startOfDay(for: day)] ?? DayMarks()
        let isSchoolDay = schoolDays.contains(calendar.component(.weekday, from: day))
        return Button { selection = day } label: {
            VStack(spacing: 2) {
                Text(day.formatted(.dateTime.day()))
                    .font(.callout.weight(isToday || isSelected ? .bold : .regular))
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? theme.onAccent : isToday ? theme.accent : isSchoolDay ? .primary : .secondary)
                    .frame(width: 32, height: 32)
                    .background { if isSelected { Circle().fill(theme.accent) } }
                    .overlay { if isToday && !isSelected { Circle().strokeBorder(theme.accent, lineWidth: 1.5) } }
                    .overlay(alignment: .topTrailing) {
                        if mark.hasTest {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.red)
                                .offset(x: 3, y: -2)
                        }
                    }
                MarkDots(marks: mark)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.armenianLongDay)
        .accessibilityValue(mark.spokenSummary)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var legend: some View {
        HStack(spacing: 10) {
            LegendItem(color: .orange, title: "Տնային")
            LegendItem(color: .green, title: "Արված")
            LegendItem(color: .blue, title: "Գրառում")
            LegendItem(color: .teal, title: "Նկար")
            HStack(spacing: 3) {
                Image(systemName: "star.fill").font(.system(size: 8, weight: .bold)).foregroundStyle(.red)
                Text("Ստուգողական")
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .accessibilityHidden(true)
    }

    // MARK: Dates

    private static let weekOrder = [2, 3, 4, 5, 6, 7, 1]

    /// Weekdays with lessons; with no timetable yet, Monday–Friday.
    private var schoolDays: Set<Int> { schoolWeekdays.isEmpty ? [2, 3, 4, 5, 6] : schoolWeekdays }

    /// Cells to draw: `nil` pads the first week of the month.
    private var days: [Date?] {
        if weekMode {
            guard let start = calendar.dateInterval(of: .weekOfYear, for: anchor)?.start else { return [] }
            return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: start) }
        }
        guard let month = calendar.dateInterval(of: .month, for: anchor),
              let count = calendar.range(of: .day, in: .month, for: anchor)?.count else { return [] }
        let lead = (calendar.component(.weekday, from: month.start) - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: lead) + (0..<count).map { calendar.date(byAdding: .day, value: $0, to: month.start) }
    }

    private func isShown(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: anchor, toGranularity: weekMode ? .weekOfYear : .month)
    }

    private func step(_ direction: Int) {
        let component: Calendar.Component = weekMode ? .weekOfYear : .month
        guard let next = calendar.date(byAdding: component, value: direction, to: anchor) else { return }
        anchor = next
    }
}

/// Up to three dots under a day number; keeps its height when empty so rows line up.
private struct MarkDots: View {
    let marks: DayMarks

    var body: some View {
        HStack(spacing: 3) {
            if marks.pendingHomework > 0 { dot(.orange) } else if marks.allDone { dot(.green) }
            if marks.hasNote { dot(.blue) }
            if marks.hasPhoto { dot(.teal) }
        }
        .frame(height: 5)
    }

    private func dot(_ color: Color) -> some View { Circle().fill(color).frame(width: 5, height: 5) }
}

private struct LegendItem: View {
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(title)
        }
    }
}

private extension DayMarks {
    var spokenSummary: String {
        var parts: [String] = []
        if pendingHomework > 0 { parts.append("\(pendingHomework) տնային") }
        if allDone { parts.append("տնայինները արված են") }
        if hasTest { parts.append("ստուգողական") }
        if hasNote { parts.append("գրառում") }
        if hasPhoto { parts.append("նկար") }
        return parts.joined(separator: ", ")
    }
}
