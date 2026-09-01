//  Copyright © 2025 ADA 4th GMG. All rights reserved.

/// The token spellings the model uses, in one place.
///
/// These strings are shared verbatim with the Python vocabulary — roots with
/// `chord_inference.preprocess.NOTE_NAMES`, qualities with the right-hand side
/// of `chord_inference.musicxml.KIND_TO_TYPE`. Both directions live here so a
/// change on one side cannot quietly disagree with the other.
///
/// This mapping was wrong for most of the model's output until now: the app
/// read `Type_M` and `Type_M7` while the vocabulary emitted `Type_maj` and
/// `Type_maj7`. Unrecognised names decode to `nil`, so plain major chords —
/// the single most common chord in the training data — vanished silently.
enum ChordToken {
    static let rootPrefix: String = "Root_"
    static let typePrefix: String = "Type_"
    static let keyPrefix: String = "Key_"
    static let timeShiftPrefix: String = "TimeShift_"
    static let pitchPrefix: String = "Pitch_"
    static let durationPrefix: String = "Duration_"
}

extension NoteName {
    /// Pitch classes are spelled with sharps; the model has one token per class.
    private static let byPitchClass: [NoteName] = [
        .C, .Cs, .D, .Ds, .E, .F, .Fs, .G, .Gs, .A, .As, .B,
    ]

    /// 0 for C through 11 for B, collapsing enharmonic spellings.
    var pitchClass: Int {
        switch self {
        case .C: return 0
        case .Cs, .Db: return 1
        case .D: return 2
        case .Ds, .Eb: return 3
        case .E: return 4
        case .F: return 5
        case .Fs, .Gb: return 6
        case .G: return 7
        case .Gs, .Ab: return 8
        case .A: return 9
        case .As, .Bb: return 10
        case .B: return 11
        }
    }

    init(pitchClass: Int) {
        let wrapped: Int = ((pitchClass % 12) + 12) % 12
        self = Self.byPitchClass[wrapped]
    }

    /// Reads a `Root_` or `Key_` token.
    init?(token: String) {
        let name: String
        if token.hasPrefix(ChordToken.rootPrefix) {
            name = String(token.dropFirst(ChordToken.rootPrefix.count))
        } else if token.hasPrefix(ChordToken.keyPrefix) {
            name = String(token.dropFirst(ChordToken.keyPrefix.count))
        } else {
            return nil
        }

        guard let match = Self.byPitchClass.first(where: { $0.description == name })
        else { return nil }
        self = match
    }

    /// The sharp spelling the model expects, e.g. `C#` for both C# and Db.
    var tokenName: String { NoteName(pitchClass: pitchClass).description }
}

extension ChordQuality {
    /// The vocabulary's spelling, which is not the display spelling.
    var tokenName: String {
        switch self {
        case .maj: return "maj"
        case .maj7: return "maj7"
        case .maj9: return "maj9"
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

    /// Reads a `Type_` token.
    init?(token: String) {
        guard token.hasPrefix(ChordToken.typePrefix) else { return nil }
        let name: String = String(token.dropFirst(ChordToken.typePrefix.count))

        guard let match = ChordQuality.allCases.first(where: { $0.tokenName == name })
        else { return nil }
        self = match
    }
}
