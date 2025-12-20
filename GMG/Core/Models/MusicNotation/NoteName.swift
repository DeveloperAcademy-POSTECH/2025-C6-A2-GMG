//  Copyright © 2025 ADA 4th GMG. All rights reserved.

enum NoteName {
    case C
    case Cs
    case Db
    case D
    case Ds
    case Eb
    case E
    case F
    case Fs
    case Gb
    case G
    case Gs
    case Ab
    case A
    case As
    case Bb
    case B
}

extension NoteName: CustomStringConvertible {
    var description: String {
        switch self {
        case .C: return "C"
        case .Cs: return "C#"
        case .Db: return "Db"
        case .D: return "D"
        case .Ds: return "D#"
        case .Eb: return "Eb"
        case .E: return "E"
        case .F: return "F"
        case .Fs: return "F#"
        case .Gb: return "Gb"
        case .G: return "G"
        case .Gs: return "G#"
        case .Ab: return "Ab"
        case .A: return "A"
        case .As: return "A#"
        case .Bb: return "Bb"
        case .B: return "B"
        }
    }
}

extension NoteName: Codable {}

extension NoteName: Hashable {}

extension NoteName: CaseIterable {}
