//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Tonic

extension Chord {
    var tonicChord: Tonic.Chord {
        var root: NoteClass = .C
        switch self.root {
        case .C: root = .C
        case .Cs: root = .Cs
        case .Db: root = .Db
        case .D: root = .D
        case .Ds: root = .Ds
        case .Eb: root = .Eb
        case .E: root = .E
        case .F: root = .F
        case .Fs: root = .Fs
        case .Gb: root = .Gb
        case .G: root = .G
        case .Gs: root = .Gs
        case .Ab: root = .Ab
        case .A: root = .A
        case .As: root = .As
        case .Bb: root = .Bb
        case .B: root = .B
        }

        var type: ChordType = .major
        switch self.quality {
        case .maj: type = .major
        case .maj7: type = .maj7
        case .maj9: type = .maj9
        case .min: type = .minor
        case .min7: type = .min7
        case .dom7: type = .dom7
        case .dom9: type = .dom9
        case .dim: type = .dim
        case .dim7: type = .dim7
        case .halfDim7: type = .halfDim7
        }

        let tonicChord: Tonic.Chord = Tonic.Chord(root, type: type)

        return tonicChord
    }
}

extension Tonic.Chord {
    var midiNoteNumbers: [Int8] {
        let pitches: [Pitch] = self.pitches(octave: 2)
        let midiNoteNumbers: [Int8] = pitches.map { pitch in
            return pitch.midiNoteNumber
        }

        return midiNoteNumbers
    }
}
