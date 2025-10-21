//  Copyright © 2025 ADA 4th GMG. All rights reserved.

enum NoteDuration {
    case whole
    case dotHalf
    case half
    case dotQuarter
    case quarter
    case dotEighth
    case eighth
    case dotSixteenth
    case sixteenth
    case dottedThirtySecond
    case thirtySecond
}

extension NoteDuration: CustomStringConvertible {
    var description: String {
        switch self {
        case .whole: "1"
        case .dotHalf: "2."
        case .half: "2"
        case .dotQuarter: "4."
        case .quarter: "4"
        case .dotEighth: "8."
        case .eighth: "8"
        case .dotSixteenth: "16."
        case .sixteenth: "16"
        case .dottedThirtySecond: "32."
        case .thirtySecond: "32"
        }
    }
}
