//  Copyright © 2025 ADA 4th GMG. All rights reserved.

enum NoteName: Codable {
    case C
    case Cs
    case Db
    case D
    case Ds
    case E
    case Fb
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
        case .Cs: return "C♯"
        case .Db: return "D♭"
        case .D: return "D"
        case .Ds: return "D♯"
        case .E: return "E"
        case .Fb: return "F♭"
        case .F: return "F"
        case .Fs: return "F♯"
        case .Gb: return "G♭"
        case .G: return "G"
        case .Gs: return "G♯"
        case .Ab: return "A♭"
        case .A: return "A"
        case .As: return "A♯"
        case .Bb: return "B♭"
        case .B: return "B"
        }
    }
}
