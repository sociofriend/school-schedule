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
        var result = try parseLayout(TextLayout.cells(from: items))
        result.entries = result.entries.map { entry in
            var entry = entry
            entry.subject = SubjectDictionary.correct(entry.subject)
            return entry
        }
        return result
    }

    private func parseLayout(_ items: [RecognizedText]) throws -> ParsedTimetable {
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
        let gridHeaders = alignedHeaders(headers, orderKey: orderKey, assignKey: assignKey, daysAreColumns: daysAreColumns)
        // Text beyond the grid (time column, titles, footers) is not a lesson.
        let reach = medianGap(gridHeaders.map { assignKey($0.box) }).map { $0 * 0.6 } ?? .greatestFiniteMagnitude
        let headerOrder = gridHeaders.map { orderKey($0.box) }.max() ?? 0

        var cells: [(weekday: Int, order: CGFloat, subject: String)] = []
        var times: [(order: CGFloat, range: PeriodRange)] = []
        var labels: [CGFloat] = [] // lesson numbers in the label column

        for (index, item) in items.enumerated() where !headerIndices.contains(index) {
            let order = orderKey(item.box)
            guard order > headerOrder else { continue } // must come after the header row/column
            if let range = TimeRangeMatcher.range(in: item.text) {
                times.append((order, range))
            }
            let nearest = gridHeaders.min { abs(assignKey($0.box) - assignKey(item.box)) < abs(assignKey($1.box) - assignKey(item.box)) }!
            let inGrid = abs(assignKey(nearest.box) - assignKey(item.box)) <= reach
            let subject = SubjectCleaner.clean(item.text)
            if !inGrid, subject.isEmpty, item.text.range(of: #"^\s*\d{1,2}(?!\d)"#, options: .regularExpression) != nil {
                labels.append(order)
            }
            guard inGrid, !subject.isEmpty else { continue }
            cells.append((nearest.weekday, order, subject))
        }

        // Lesson rows: the time/number column when read (a wrapped cell then stays in its row),
        // else all positions clustered, so empty cells keep correct period numbers.
        let tolerance = rowTolerance(items.map { daysAreColumns ? $0.box.height : $0.box.width })
        let anchors = cluster(times.map(\.order) + labels, tolerance: tolerance)
        let rows = anchors.count >= 2 ? anchors : cluster(cells.map(\.order) + times.map(\.order), tolerance: tolerance)
        func period(for order: CGFloat) -> Int {
            if anchors.count >= 2 {
                return rows.indices.min { abs(rows[$0] - order) < abs(rows[$1] - order) }! + 1
            }
            return (rows.firstIndex { abs($0 - order) <= tolerance } ?? rows.count) + 1
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

    /// Keeps headers on the header row (or column), then fills days whose header was not read:
    /// a gap of n columns between two read days that are n school days apart gets the days in between.
    private func alignedHeaders(_ headers: [Header], orderKey: (CGRect) -> CGFloat, assignKey: (CGRect) -> CGFloat,
                                daysAreColumns: Bool) -> [Header] {
        let orders = headers.map { orderKey($0.box) }.sorted()
        let line = orders[orders.count / 2]
        let sizes = headers.map { daysAreColumns ? $0.box.height : $0.box.width }.sorted()
        let tolerance = sizes[sizes.count / 2] * 2
        let aligned = headers.filter { abs(orderKey($0.box) - line) <= tolerance }
            .sorted { daysAreColumns ? assignKey($0.box) < assignKey($1.box) : assignKey($0.box) > assignKey($1.box) }
        guard let step = medianGap(aligned.map { assignKey($0.box) }) else { return aligned }

        let week = Weekday.schoolWeek + [1]
        var result = aligned
        for (a, b) in zip(aligned, aligned.dropFirst()) {
            guard let i = week.firstIndex(of: a.weekday), let j = week.firstIndex(of: b.weekday) else { continue }
            let missing = Int((abs(assignKey(b.box) - assignKey(a.box)) / step).rounded()) - 1
            guard missing > 0, j - i == missing + 1 else { continue }
            let dx = (b.box.midX - a.box.midX) / CGFloat(missing + 1), dy = (b.box.midY - a.box.midY) / CGFloat(missing + 1)
            for k in 1...missing {
                result.append((index: -1, weekday: week[i + k], box: a.box.offsetBy(dx: dx * CGFloat(k), dy: dy * CGFloat(k))))
            }
        }
        return result
    }

    /// Median distance between neighbouring values; nil with fewer than two.
    func medianGap(_ values: [CGFloat]) -> CGFloat? {
        let sorted = values.sorted()
        let gaps = zip(sorted, sorted.dropFirst()).map { $1 - $0 }.filter { $0 > 0 }.sorted()
        return gaps.isEmpty ? nil : gaps[gaps.count / 2]
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
    /// Full names per `Calendar` weekday.
    private static let fullNames: [Int: [String]] = [
        1: ["կիրակի", "sunday", "воскресенье"],
        2: ["երկուշաբթի", "monday", "понедельник"],
        3: ["երեքշաբթի", "tuesday", "вторник"],
        4: ["չորեքշաբթի", "wednesday", "среда"],
        5: ["հինգշաբթի", "thursday", "четверг"],
        6: ["ուրբաթ", "friday", "пятница"],
        7: ["շաբաթ", "saturday", "суббота"],
    ]
    /// Abbreviations, with or without the trailing dot (`երկ.`, `երկ․`).
    private static let abbreviations: [Int: [String]] = [
        1: ["կիր", "կրկ", "sun", "вс", "вск"],
        2: ["երկ", "երկշ", "երկու", "mon", "пн", "пон"],
        3: ["երք", "երեք", "երքշ", "երեքշ", "tue", "tues", "вт", "вто"],
        4: ["չրք", "չոր", "չորք", "չորեք", "չրքշ", "wed", "ср", "сре"],
        5: ["հնգ", "հինգ", "հնգշ", "thu", "thur", "thurs", "чт", "чет"],
        6: ["ուրբ", "ուր", "fri", "пт", "пят"],
        7: ["շբթ", "շաբ", "sat", "сб", "суб"],
    ]
    /// Latin/Cyrillic glyphs OCR returns for look-alike Armenian lowercase letters.
    private static let lookAlikes: [Character: Character] = [
        "h": "հ", "n": "ո", "u": "ս", "q": "զ", "g": "գ", "d": "դ", "o": "օ", "w": "ա", "ш": "ա", "l": "լ",
    ]

    /// The weekday a header names: its first word (dates and dots ignored), exact or within a small edit distance.
    static func weekday(in text: String) -> Int? {
        let words = text.lowercased().split { !$0.isLetter }
        guard text.count <= 24, (1...2).contains(words.count), var word = words.first.map(String.init) else { return nil }
        if word.contains(where: isArmenian) { word = String(word.map { lookAlikes[$0] ?? $0 }) }

        var best: (weekday: Int, distance: Int)?, runnerUp = Int.max
        for weekday in 1...7 {
            let candidates: [(String, Int)] = fullNames[weekday, default: []].map { ($0, $0.count >= 8 ? 2 : 1) }
                + abbreviations[weekday, default: []].map { ($0, $0.count >= 4 ? 1 : 0) }
            for (name, allowed) in candidates {
                let distance = SubjectDictionary.editDistance(Array(word), Array(name))
                guard distance <= allowed else { continue }
                if distance < best?.distance ?? .max {
                    if let best, best.weekday != weekday { runnerUp = best.distance }
                    best = (weekday, distance)
                } else if weekday != best?.weekday {
                    runnerUp = min(runnerUp, distance)
                }
            }
        }
        // Ambiguous misreadings (e.g. equally close to երեքշաբթի and չորեքշաբթի) are rejected.
        guard let best, best.distance < runnerUp else { return nil }
        return best.weekday
    }

    private static func isArmenian(_ character: Character) -> Bool {
        character.unicodeScalars.contains { (0x0531...0x058F).contains($0.value) }
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
    private static let leadingNumber = try! NSRegularExpression(pattern: #"^\s*\d{1,2}\s*(?:-?\s*(?:ին|րդ)(?!\p{L})|[.)\-])?\s*"#, options: .caseInsensitive)
    /// Row labels and table furniture, never a subject on their own.
    private static let labels: Set<String> = ["դաս", "դասաժամ", "ժամ", "ին", "րդ", "օր", "lesson", "урок"]
    private static let timeRange = try! NSRegularExpression(pattern: #"\d{1,2}[:.]\d{2}\s*[-–—]?\s*(\d{1,2}[:.]\d{2})?"#)

    /// Removes lesson numbers (`2.`, `2-րդ`) and times; returns "" when nothing meaningful remains
    /// (labels, or OCR noise such as a table border read as `l`).
    static func clean(_ text: String) -> String {
        var value = text
        for regex in [timeRange, leadingNumber] {
            value = regex.stringByReplacingMatches(in: value, range: NSRange(value.startIndex..., in: value), withTemplate: "")
        }
        value = value.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        guard value.filter(\.isLetter).count >= 2, !labels.contains(value.lowercased()) else { return "" }
        return value
    }
}

/// Joins OCR words into cell phrases: same line, small gap, and never letters with bare numbers
/// (so a period's time column does not swallow the first lesson). A run holding two or more weekday
/// names (a header row read as one phrase) stays split into words.
enum TextLayout {
    private enum Kind { case letters, digits, neutral }

    static func cells(from words: [RecognizedText]) -> [RecognizedText] {
        let heights = words.map(\.box.height).sorted()
        guard !heights.isEmpty else { return [] }
        let gapLimit = heights[heights.count / 2]

        var runs: [[RecognizedText]] = []
        for word in words.sorted(by: { $0.box.minX < $1.box.minX }) {
            let index = runs.lastIndex { run in
                let last = run[run.count - 1]
                return abs(last.box.midY - word.box.midY) <= max(last.box.height, word.box.height) / 2
                    && word.box.minX - last.box.maxX <= gapLimit
                    && compatible(kind(of: run), kind(of: [word]))
            }
            if let index { runs[index].append(word) } else { runs.append([word]) }
        }
        return runs.flatMap { run -> [RecognizedText] in
            if run.count > 1, run.filter({ WeekdayMatcher.weekday(in: $0.text) != nil }).count >= 2 { return run }
            return [RecognizedText(text: run.map(\.text).joined(separator: " "),
                                   box: run.dropFirst().reduce(run[0].box) { $0.union($1.box) })]
        }
    }

    private static func kind(of run: [RecognizedText]) -> Kind {
        for word in run {
            let letters = word.text.contains(where: \.isLetter), digits = word.text.contains(where: \.isNumber)
            if letters != digits { return letters ? .letters : .digits }
        }
        return .neutral
    }

    private static func compatible(_ a: Kind, _ b: Kind) -> Bool {
        a == .neutral || b == .neutral || a == b
    }
}
