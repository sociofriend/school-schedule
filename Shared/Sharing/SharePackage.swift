import Foundation

/// What one kid sends another: a homework task or a whole timetable. Plain JSON, no backend.
struct SharePackage: Codable, Hashable, Sendable {
    struct Task: Codable, Hashable, Sendable {
        var title: String
        var subject: String
        var dueDate: Date
    }

    enum Content: Codable, Hashable, Sendable {
        case task(Task)
        case timetable(Timetable)
    }

    static let currentVersion = 1

    var version = SharePackage.currentVersion
    var sender: String
    var sentAt: Date = .now
    var content: Content

    init(sender: String, content: Content) {
        self.sender = sender
        self.content = content
    }

    init(task: TaskItem, sender: String) {
        self.init(sender: sender, content: .task(.init(title: task.title, subject: task.subject, dueDate: task.dueDate)))
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> SharePackage {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SharePackage.self, from: data)
    }

    /// Short name for the file and the share sheet.
    var title: String {
        switch content {
        case .task(let task): task.subject.isEmpty ? "Առաջադրանք" : "Առաջադրանք՝ \(task.subject)"
        case .timetable: "Դասացուցակ"
        }
    }

    /// Readable text sent next to the file, for someone without the app.
    var readableText: String {
        var lines: [String]
        switch content {
        case .task(let task):
            lines = ["📚 \(title)", task.title, "Ժամկետ՝ \(task.dueDate.armenianShortDay)"]
        case .timetable(let timetable):
            lines = ["🗓 Դասացուցակ"]
            for weekday in Weekday.schoolWeek {
                let day = timetable.entries.filter { $0.weekday == weekday }.sorted { $0.period < $1.period }
                guard !day.isEmpty else { continue }
                lines.append("")
                lines.append(Weekday.name(weekday))
                lines += day.map { entry in
                    let time = timetable.periods[entry.period].map { " (\(PeriodRange.format($0.start)))" } ?? ""
                    return "\(entry.period). \(entry.subject)\(time)"
                }
            }
        }
        lines += ["", sender.isEmpty ? "«Դասացուցակ» հավելվածից" : "Ուղարկեց՝ \(sender) («Դասացուցակ» հավելվածից)"]
        return lines.joined(separator: "\n")
    }
}

extension Timetable {
    /// Adds `other`'s lessons only where this timetable has a free slot; keeps own bell times, fills missing ones.
    func merged(with other: Timetable) -> Timetable {
        let taken = Set(entries.map { [$0.weekday, $0.period] })
        let added = other.entries.filter { !taken.contains([$0.weekday, $0.period]) }
        return Timetable(entries: entries + added, periods: periods.merging(other.periods) { own, _ in own })
    }
}
