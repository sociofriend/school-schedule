import Foundation

/// Official subject lists per grade (ՀՀ ԿԳՄՍՆ, Հանրակրթության պետական չափորոշիչ N 136-Ն), for quick picks in the timetable.
enum ArmenianCurriculum {
    static let grades = 1...12

    /// "1-ին դասարան", "2-րդ դասարան", …
    static func gradeName(_ grade: Int) -> String {
        "\(grade)-\(grade == 1 ? "ին" : "րդ") դասարան"
    }

    /// Subjects for a grade, in curriculum order; empty outside 1...12.
    static func subjects(for grade: Int) -> [String] {
        switch grade {
        case 1: grade1
        case 2: grade2
        case 3, 4: grade3to4
        case 5: grade5
        case 6: grade6
        case 7: grade7
        case 8: grade8
        case 9: grade9
        case 10...12: grade10to12
        default: []
        }
    }

    /// Every subject of every grade once, in first-seen order (shown when no grade is set).
    static let allSubjects: [String] = {
        var seen = Set<String>()
        return grades.flatMap(subjects(for:)).filter { seen.insert($0).inserted }
    }()

    private static let languages = ["Ռուսաց լեզու", "Անգլերեն", "Ֆրանսերեն", "Գերմաներեն"]
    private static let digital = "Թվային գրագիտություն և համակարգչային գիտություն"
    private static let arts = ["Կերպարվեստ", "Երաժշտություն", "Տեխնոլոգիա", "Ֆիզկուլտուրա"]
    private static let sciences = ["Ֆիզիկա", "Քիմիա", "Կենսաբանություն", "Աշխարհագրություն",
                                   "Հայաստանի պատմություն", "Համաշխարհային պատմություն", "Հասարակագիտություն", digital]
    private static let military = "Նախնական զինվորական պատրաստություն (ՆԶՊ)"

    private static let grade1 = ["Մայրենի", "Մաթեմատիկա", "Ես և շրջակա աշխարհը"] + arts
    private static let grade2 = ["Մայրենի", "Մաթեմատիկա", "Ռուսաց լեզու", "Անգլերեն", "Ես և շրջակա աշխարհը", digital, "Շախմատ"] + arts
    private static let grade3to4 = ["Մայրենի", "Մաթեմատիկա"] + languages + ["Ես և շրջակա աշխարհը", digital, "Շախմատ"] + arts
    private static let grade5 = ["Հայոց լեզու", "Գրականություն", "Մաթեմատիկա"] + languages
        + ["Բնություն", "Իմ հայրենիքը", digital] + arts
    private static let grade6 = ["Հայոց լեզու", "Գրականություն", "Մաթեմատիկա"] + languages
        + ["Բնություն", "Իմ հայրենիքն ու աշխարհը", "Հայոց պատմություն", "Համաշխարհային պատմություն", digital] + arts
    private static let grade7 = ["Հայոց լեզու", "Գրականություն", "Հանրահաշիվ", "Երկրաչափություն"] + languages + sciences + arts
    private static let grade8 = ["Հայոց լեզու", "Գրականություն", "Հանրահաշիվ", "Երկրաչափություն"] + languages + sciences
        + ["Տեխնոլոգիա", military, "Առողջ ապրելակերպ", "Ֆիզկուլտուրա"]
    private static let grade9 = ["Հայոց լեզու", "Գրականություն", "Հանրահաշիվ", "Երկրաչափություն"] + languages + sciences
        + [military, "Առողջ ապրելակերպ", "Ֆիզկուլտուրա"]
    private static let grade10to12 = ["Հայոց լեզու", "Հայ գրականություն", "Հանրահաշիվ և մաթեմատիկական անալիզի տարրեր", "Երկրաչափություն"]
        + languages + sciences + [military, "Ֆիզկուլտուրա"]
}
