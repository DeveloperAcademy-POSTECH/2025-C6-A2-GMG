//  Copyright © 2025 ADA 4th GMG. All rights reserved.

enum ChordQuality {
    case maj
    case maj7
    case maj9
    case min
    case min7
    case dom7
    case dom9
    case dim
    case dim7
    case halfDim7
}

extension ChordQuality: CustomStringConvertible {
    var description: String {
        switch self {
        case .maj: return ""
        case .maj7: return "M7"
        case .maj9: return "M9"
        case .min: return "m"
        case .min7: return "m7"
        case .dom7: return "7"
        case .dom9: return "9"
        case .dim: return "dim"
        case .dim7: return "dim7"
        case .halfDim7: return "m7b5"
        }
    }
}

extension ChordQuality: Codable {}

extension ChordQuality: Hashable {}
