//  Copyright © 2025 ADA 4th GMG. All rights reserved.

enum ChordQuality: Codable {
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
        case .maj: return "maj"
        case .maj7: return "maj7"
        case .maj9: return "maj9"
        case .min: return "min"
        case .min7: return "min7"
        case .dom7: return "7"
        case .dom9: return "9"
        case .dim: return "dim"
        case .dim7: return "dim7"
        case .halfDim7: return "hdim7"
        }
    }
}
