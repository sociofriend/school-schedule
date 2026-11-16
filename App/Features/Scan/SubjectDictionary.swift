import Foundation

/// Snaps OCR'd subject names to known Armenian school subjects.
/// Tesseract often confuses `Հ/հ` with `Ը`, `Շ` or `ճ` in screen fonts; a close match to a known name wins.
enum SubjectDictionary {
    static let known = [
        "Հայոց լեզու", "Մայրենի", "Գրականություն", "Ռուսաց լեզու", "Անգլերեն", "Ֆրանսերեն", "Գերմաներեն",
        "Մաթեմատիկա", "Մաթեմատիկայի հատուկ դասընթաց", "Հանրահաշիվ", "Երկրաչափություն",
        "Ֆիզիկա", "Քիմիա", "Կենսաբանություն", "Աշխարհագրություն", "Բնագիտություն", "Ես և շրջակա աշխարհը",
        "Հայաստանի պատմություն", "Համաշխարհային պատմություն", "Հայ եկեղեցու պատմություն", "Հասարակագիտություն",
        "Ֆիզկուլտուրա", "Ֆիզիկական դաստիարակություն", "Երաժշտություն", "Կերպարվեստ", "Արվեստ", "Տեխնոլոգիա",
        "Ինֆորմատիկա", "Թվային գրագիտություն և համակարգչային գիտություն", "Շախմատ", "Առողջ ապրելակերպ",
        "Նախնական զինվորական պատրաստություն",
    ]

    /// Minimum similarity (1 − edit distance / length) to accept a known name.
    static let threshold = 0.75

    static func correct(_ subject: String) -> String {
        let cleaned = subject.replacingOccurrences(of: "ԸՇ", with: "Հ")
        guard let best = known
            .map({ (name: $0, score: similarity(cleaned, $0)) })
            .max(by: { $0.score < $1.score }),
              best.score >= threshold else { return cleaned }
        return best.name
    }

    static func similarity(_ a: String, _ b: String) -> Double {
        let a = Array(a.lowercased()), b = Array(b.lowercased())
        let longest = max(a.count, b.count)
        guard longest > 0 else { return 1 }
        return 1 - Double(editDistance(a, b)) / Double(longest)
    }

    static func editDistance(_ a: [Character], _ b: [Character]) -> Int {
        guard !a.isEmpty else { return b.count }
        guard !b.isEmpty else { return a.count }
        var previous = Array(0...b.count)
        for i in 1...a.count {
            var current = [i] + Array(repeating: 0, count: b.count)
            for j in 1...b.count {
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1))
            }
            previous = current
        }
        return previous[b.count]
    }
}
