import CoreGraphics
import Foundation

/// Card layout used by school e-diaries (weekly calendar view):
/// one column per day, each lesson a card of `08:15 – 09:00` / subject (may wrap) / status (`Ներկա`).
/// Cards starting with a short tag (`ԽՄ ·`, `ՆՈՒ ·`) are lesson topics, not subjects, and are skipped.
extension TimetableParser {
    func parseCards(_ items: [RecognizedText], headers: [Header]) -> ParsedTimetable? {
        let anchorIndices = items.indices.filter {
            TimeRangeMatcher.range(in: items[$0].text) != nil && SubjectCleaner.clean(items[$0].text).isEmpty
        }
        guard anchorIndices.count >= 3 else { return nil }

        // Column left edges: card texts are left-aligned, so time ranges share a minX per column.
        let anchorWidths = anchorIndices.map { items[$0].box.width }.sorted()
        let edgeTolerance = max(anchorWidths[anchorWidths.count / 2] * 0.5, 0.01)
        let edges = cluster(anchorIndices.map { items[$0].box.minX }, tolerance: edgeTolerance)
        guard !edges.isEmpty else { return nil }

        let columnWeekdays = weekdays(forColumnsAt: edges, tolerance: edgeTolerance, headers: headers)
        let headerIndices = Set(headers.map(\.index))

        // Assign every text to the right-most column whose left edge it starts after.
        var columns = Array(repeating: [RecognizedText](), count: edges.count)
        for (index, item) in items.enumerated() where !headerIndices.contains(index) {
            guard let column = edges.lastIndex(where: { $0 - edgeTolerance <= item.box.minX }) else { continue }
            columns[column].append(item)
        }

        struct Card { let range: PeriodRange; var lines: [String] = [] }
        var cardsByWeekday: [Int: [Card]] = [:]
        for (column, texts) in columns.enumerated() {
            var cards: [Card] = []
            for item in texts.sorted(by: { $0.box.maxY > $1.box.maxY }) {
                if let range = TimeRangeMatcher.range(in: item.text), SubjectCleaner.clean(item.text).isEmpty {
                    cards.append(Card(range: range))
                } else if !cards.isEmpty {
                    cards[cards.count - 1].lines.append(item.text) // text above the first card (dates, "8 դաս") is ignored
                }
            }
            cardsByWeekday[columnWeekdays[column], default: []] += cards
        }

        // Lesson numbers follow the distinct start times across the week.
        let starts = Set(cardsByWeekday.values.flatMap { $0.map(\.range.start) }).sorted()
        var result = ParsedTimetable()
        for (weekday, cards) in cardsByWeekday {
            var used = Set<Int>()
            for card in cards {
                guard let subject = CardLine.subject(from: card.lines),
                      let index = starts.firstIndex(of: card.range.start) else { continue }
                let period = index + 1
                result.periods[period] = card.range
                guard used.insert(period).inserted else { continue }
                result.entries.append(TimetableEntry(weekday: weekday, period: period, subject: subject))
            }
        }
        return result
    }

    /// Each column takes the left-most weekday header that sits between its left edge and the next column;
    /// without headers (e.g. OCR could not read them) columns are assumed Monday-first.
    private func weekdays(forColumnsAt edges: [CGFloat], tolerance: CGFloat, headers: [Header]) -> [Int] {
        let week = Weekday.schoolWeek + [1]
        return edges.indices.map { index in
            let next = index + 1 < edges.count ? edges[index + 1] - tolerance : .greatestFiniteMagnitude
            let candidates = headers.filter { $0.box.midX >= edges[index] - tolerance && $0.box.midX < next }
            return candidates.min { $0.box.midX < $1.box.midX }?.weekday ?? week[min(index, week.count - 1)]
        }
    }
}

enum CardLine {
    private static let statusPrefixes = ["ներկա", "բացակա", "ուշաց", "present", "absent", "late", "присут", "отсут", "опозд"]
    private static let tag = try! NSRegularExpression(pattern: #"^\s*\p{Lu}{1,4}\s*[·•∙.]"#)

    static func isStatus(_ line: String) -> Bool {
        let value = line.lowercased().trimmingCharacters(in: .whitespaces)
        return statusPrefixes.contains(where: value.hasPrefix)
    }

    static func isTag(_ line: String) -> Bool {
        tag.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil
    }

    /// Subject = lines before the status line; nil for topic cards (starting with a tag).
    static func subject(from lines: [String]) -> String? {
        guard let first = lines.first, !isTag(first) else { return nil }
        let subjectLines = lines.prefix { !isStatus($0) }.map(SubjectCleaner.clean).filter { !$0.isEmpty }
        let subject = subjectLines.joined(separator: " ")
        return subject.isEmpty ? nil : subject
    }
}
