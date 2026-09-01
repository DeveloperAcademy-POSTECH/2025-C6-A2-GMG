//  Copyright © 2025 ADA 4th GMG. All rights reserved.

/// The chord qualities the model can predict.
///
/// The raw spellings in `Chord+Token` are shared verbatim with the Python
/// vocabulary (`chord_inference.musicxml.KIND_TO_TYPE`). Model and app must
/// agree on them exactly: a name the app does not recognise is dropped, and
/// the chord disappears from the score without any error.
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
    case sus4
    case aug
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
        case .sus4: return "sus4"
        case .aug: return "aug"
        }
    }
}

extension ChordQuality: Codable {}

extension ChordQuality: Hashable {}

extension ChordQuality: CaseIterable {}
