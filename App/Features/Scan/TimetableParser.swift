import CoreGraphics
import Foundation

/// A recognized text line. `box` is normalized with Vision's bottom-left origin.
struct RecognizedText: Equatable, Sendable {
    let text: String
    let box: CGRect
}

struct ParsedTimetable: Equatable, Sendable {
    var entries: [TimetableEntry] = []
    var periods: [Int: PeriodRange] = [:]

    mutating func merge(_ other: ParsedTimetable) {
        let replaced = Set(other.entries.map(\.weekday))
        entries.removeAll { replaced.contains($0.weekday) }
        entries += other.entries
        periods.merge(other.periods) { _, new in new }
    }
}

/// Turns OCR output of a timetable photo into a grid using text positions.
/// Supports weekdays as column headers (most common) or as row headers.
struct TimetableParser {
    enum ParseError: LocalizedError {
        case noWeekdaysFound
        var errorDescription: String? { "Շաբաթվա օրերը չհաջողվեց ճանաչել։" }
    }

    typealias Header = (index: Int, weekday: Int, box: CGRect)

    func parse(_ items: [RecognizedText]) throws -> ParsedTimetable {
        let headers: [Header] = items.indices.compactMap { index in
            WeekdayMatcher.weekday(in: items[index].text).map { (index: index, weekday: $0, box: items[index].box) }
        }
        // E-diary style: columns of cards, each starting with a time range.
        if let cards = parseCards(items, headers: headers), !cards.entries.isEmpty { return cards }
        guard !headers.isEmpty else { throw ParseError.noWeekdaysFound }

        let headerSpreadX = spread(headers.map(\.box.midX))
        let headerSpreadY = spread(headers.map(\.box.midY))
        let daysAreColumns = headers.count == 1 || headerSpreadX >= headerSpreadY

        // Axis along which a day's lessons are laid out, and its "reading order" value.
        let assignKey: (CGRect) -> CGFloat = daysAreColumns ? { $0.midX } : { $0.midY }
        let orderKey: (CGRect) -> CGFloat = daysAreColumns ? { -$0.midY } : { $0.midX }

        let headerIndices = Set(headers.map(\.index))
        let headerOrder = headers.map { orderKey($0.box) }.max() ?? 0

        var cells: [(weekday: Int, order: CGFloat, subject: String)] = []
        var times: [(order: CGFloat, range: PeriodRange)] = []

        for (index, item) in items.enumerated() where !headerIndices.contains(index) {
            let order = orderKey(item.box)
            guard order > headerOrder else { continue } // must come after the header row/column
            if let range = TimeRangeMatcher.range(in: item.text) {
                times.append((order, range))
            }
            let subject = SubjectCleaner.clean(item.text)
            guard !subject.isEmpty else { continue }
            let nearest = headers.min { abs(assignKey($0.box) - assignKey(item.box)) < abs(assignKey($1.box) - assignKey(item.box)) }
            guard let weekday = nearest?.weekday else { continue }
            cells.append((weekday, order, subject))
        }

        // Cluster all positions into lesson rows so empty cells keep correct period numbers.
        let tolerance = rowTolerance(items.map { daysAreColumns ? $0.box.height : $0.box.width })
        let rows = cluster(cells.map(\.order) + times.map(\.order), tolerance: tolerance)
        func period(for order: CGFloat) -> Int {
            (rows.firstIndex { abs($0 - order) <= tolerance } ?? rows.count) + 1
        }

        var result = ParsedTimetable()
        var seen = Set<[Int]>()
        for cell in cells.sorted(by: { $0.order < $1.order }) {
            let number = period(for: cell.order)
            // A wrapped second line of the same cell joins the first one.
            if seen.contains([cell.weekday, number]),
               let index = result.entries.firstIndex(where: { $0.weekday == cell.weekday && $0.period == number }) {
                result.entries[index].subject += " " + cell.subject
                continue
            }
            seen.insert([cell.weekday, number])
            result.entries.append(TimetableEntry(weekday: cell.weekday, period: number, subject: cell.subject))
        }
        for time in times { result.periods[period(for: time.order)] = time.range }
        return result
    }

    func spread(_ values: [CGFloat]) -> CGFloat {
        (values.max() ?? 0) - (values.min() ?? 0)
    }

    func rowTolerance(_ sizes: [CGFloat]) -> CGFloat {
        let sorted = sizes.sorted()
        guard !sorted.isEmpty else { return 0.02 }
        return max(sorted[sorted.count / 2] * 0.6, 0.005)
    }

    /// Returns cluster centers in ascending order.
    func cluster(_ values: [CGFloat], tolerance: CGFloat) -> [CGFloat] {
        var centers: [(sum: CGFloat, count: Int)] = []
        for value in values.sorted() {
            if let last = centers.last, value - last.sum / CGFloat(last.count) <= tolerance {
                centers[centers.count - 1] = (last.sum + value, last.count + 1)
            } else {
                centers.append((value, 1))
            }
        }
        return centers.map { $0.sum / CGFloat($0.count) }
    }
}

enum WeekdayMatcher {
    /// Full names (prefix match) per `Calendar` weekday.
    private static let fullNames: [Int: [String]] = [
        1: ["կիրակի", "sunday", "воскресенье"],
        2: ["երկուշաբթի", "monday", "понедельник"],
        3: ["երեքշաբթի", "tuesday", "вторник"],
        4: ["չորեքշաբթի", "wednesday", "среда"],
        5: ["հինգշաբթի", "thursday", "четверг"],
        6: ["ուրբաթ", "friday", "пятница"],
        7: ["շաբաթ", "saturday", "суббота"],
    ]
    /// Abbreviations (exact match).
    private static let abbreviations: [Int: [String]] = [
        1: ["կիր", "sun", "вс", "вск"],
        2: ["երկ", "երկշ", "mon", "пн", "пон"],
        3: ["երք", "երեք", "երքշ", "tue", "tues", "вт", "вто"],
        4: ["չրք", "չոր", "չորք", "wed", "ср", "сре"],
        5: ["հնգ", "հինգ", "thu", "thur", "thurs", "чт", "чет"],
        6: ["ուրբ", "fri", "пт", "пят"],
        7: ["շբթ", "շաբ", "sat", "сб", "суб"],
    ]

    static func weekday(in text: String) -> Int? {
        let token = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        guard !token.isEmpty, token.count <= 14 else { return nil }
        if let match = fullNames.first(where: { $0.value.contains(where: token.hasPrefix) }) { return match.key }
        return abbreviations.first { $0.value.contains(token) }?.key
    }
}

enum TimeRangeMatcher {
    private static let regex = try! NSRegularExpression(pattern: #"(\d{1,2})[:.](\d{2})\s*[-–—]\s*(\d{1,2})[:.](\d{2})"#)

    static func range(in text: String) -> PeriodRange? {
        let ns = text as NSString
        guard let m = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)) else { return nil }
        let n = (1...4).compactMap { Int(ns.substring(with: m.range(at: $0))) }
        guard n.count == 4, n[0] < 24, n[2] < 24, n[1] < 60, n[3] < 60 else { return nil }
        let range = PeriodRange(start: n[0] * 60 + n[1], end: n[2] * 60 + n[3])
        return range.end > range.start ? range : nil
    }
}

enum SubjectCleaner {
    private static let leadingNumber = try! NSRegularExpression(pattern: #"^\s*\d{1,2}\s*[.)\-]?\s*"#)
    private static let timeRange = try! NSRegularExpression(pattern: #"\d{1,2}[:.]\d{2}\s*[-–—]?\s*(\d{1,2}[:.]\d{2})?"#)

    /// Removes lesson numbers and times; returns "" when nothing meaningful remains.
    static func clean(_ text: String) -> String {
        var value = text
        for regex in [timeRange, leadingNumber] {
            value = regex.stringByReplacingMatches(in: value, range: NSRange(value.startIndex..., in: value), withTemplate: "")
        }
        value = value.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        return value.contains(where: \.isLetter) ? value : ""
    }
}
