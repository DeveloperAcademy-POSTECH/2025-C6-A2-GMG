//  Copyright © 2025 ADA 4th GMG. All rights reserved.

enum ChordQuality {
    case eleven
    case seven
    case nine
    case aug
    case maj
    case maj6
    case maj9
    case min
    case min11
    case min6
    case min7
    case min9
    case minmaj7
    case sus2
    case sus4
}

extension ChordQuality: CustomStringConvertible {
    var description: String {
        switch self {
        case .eleven: "11"
        case .seven: "7"
        case .nine: "9"
        case .aug: "aug"
        case .maj: "maj"
        case .maj6: "maj6"
        case .maj9: "maj9"
        case .min: "min"
        case .min11: "min11"
        case .min6: "min6"
        case .min7: "min7"
        case .min9: "min9"
        case .minmaj7: "minmaj7"
        case .sus2: "sus2"
        case .sus4: "sus4"
        }
    }
}
