//  Copyright © 2025 ADA 4th GMG. All rights reserved.

enum GuitarString: Int, CaseIterable {
    case lowE = 6
    case A = 5
    case D = 4
    case G = 3
    case B = 2
    case highE = 1
}

enum Finger: Int {
    case index = 1
    case middle = 2
    case ring = 3
    case pinky = 4
}

enum GuitarStringState: Equatable {
    case mute
    case open
    case fretted(fret: Int, finger: Finger?)
}

struct Barre {
    let fret: Int
    let finger: Finger
    let from: GuitarString
    let to: GuitarString
}

struct GuitarChordDiagram {
    let startFret: Int

    let strings: [GuitarString: GuitarStringState]
    let barres: [Barre]

    private init(startFret: Int, strings: [GuitarString: GuitarStringState], barres: [Barre]) {
        self.startFret = startFret
        self.strings = strings
        self.barres = barres
    }

    init?(chord: Chord) {
        let normalizedChord: Chord = .init(
            root: chord.root.convertToSharp(), quality: chord.quality)

        guard let diagram = GuitarChordDiagram.standardLibrary[normalizedChord] else { return nil }
        self = diagram
    }
}

extension GuitarChordDiagram {
    static let empty: GuitarChordDiagram = .init(startFret: 0, strings: [:], barres: [])
}

extension NoteName {
    fileprivate func convertToSharp() -> NoteName {
        return switch self {
        case .Db: .Cs
        case .Eb: .Ds
        case .Gb: .Fs
        case .Ab: .Gs
        case .Bb: .As
        default: self
        }
    }
}

extension GuitarChordDiagram {
    private static let standardLibrary: [Chord: GuitarChordDiagram] = [
        .init(root: .C, quality: .maj): .init(
            startFret: 0,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 3, finger: .ring),
                .D: .fretted(fret: 2, finger: .middle), .G: .open,
                .B: .fretted(fret: 1, finger: .index), .highE: .open,
            ],
            barres: []
        ),
        .init(root: .C, quality: .maj7): .init(
            startFret: 0,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 3, finger: .ring),
                .D: .fretted(fret: 2, finger: .middle), .G: .open, .B: .open, .highE: .open,
            ], barres: []
        ),
        .init(root: .C, quality: .min): .init(
            startFret: 3,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 3, finger: .index),
                .D: .fretted(fret: 5, finger: .ring), .G: .fretted(fret: 5, finger: .pinky),
                .B: .fretted(fret: 4, finger: .middle), .highE: .fretted(fret: 3, finger: .index),
            ], barres: [.init(fret: 3, finger: .index, from: .A, to: .highE)]
        ),
        .init(root: .C, quality: .dom7): .init(
            startFret: 0,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 3, finger: .ring),
                .D: .fretted(fret: 2, finger: .middle), .G: .fretted(fret: 3, finger: .pinky),
                .B: .fretted(fret: 1, finger: .index), .highE: .open,
            ], barres: []
        ),
        .init(root: .C, quality: .maj9): .init(
            startFret: 0,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 3, finger: .middle),
                .D: .fretted(fret: 2, finger: .index), .G: .fretted(fret: 4, finger: .pinky),
                .B: .fretted(fret: 3, finger: .ring), .highE: .mute,
            ], barres: []
        ),
        .init(root: .C, quality: .min7): .init(
            startFret: 3,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 3, finger: .index),
                .D: .fretted(fret: 5, finger: .ring), .G: .fretted(fret: 3, finger: .index),
                .B: .fretted(fret: 4, finger: .middle), .highE: .fretted(fret: 3, finger: .index),
            ], barres: [.init(fret: 3, finger: .index, from: .A, to: .highE)]
        ),
        .init(root: .C, quality: .dom9): .init(
            startFret: 0,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 3, finger: .middle),
                .D: .fretted(fret: 2, finger: .index), .G: .fretted(fret: 3, finger: .ring),
                .B: .fretted(fret: 3, finger: .pinky), .highE: .mute,
            ], barres: []
        ),
        .init(root: .C, quality: .dim): .init(
            startFret: 1,
            strings: [
                .lowE: .mute, .A: .mute, .D: .fretted(fret: 1, finger: .index),
                .G: .fretted(fret: 2, finger: .ring), .B: .fretted(fret: 1, finger: .middle),
                .highE: .mute,
            ], barres: []
        ),
        .init(root: .C, quality: .dim7): .init(
            startFret: 1,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 3, finger: .middle),
                .D: .fretted(fret: 4, finger: .ring), .G: .fretted(fret: 2, finger: .index),
                .B: .fretted(fret: 4, finger: .pinky), .highE: .mute,
            ], barres: []
        ),
        .init(root: .C, quality: .halfDim7): .init(
            startFret: 3,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 3, finger: .middle),
                .D: .fretted(fret: 4, finger: .ring), .G: .fretted(fret: 3, finger: .index),
                .B: .fretted(fret: 4, finger: .pinky), .highE: .mute,
            ], barres: []
        ),

        // MARK: - Root C# (A Shape Barre at Fret 4)

        .init(root: .Cs, quality: .maj): .init(
            startFret: 4,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 4, finger: .index),
                .D: .fretted(fret: 6, finger: .middle), .G: .fretted(fret: 6, finger: .ring),
                .B: .fretted(fret: 6, finger: .pinky), .highE: .fretted(fret: 4, finger: .index),
            ], barres: [.init(fret: 4, finger: .index, from: .A, to: .highE)]
        ),
        .init(root: .Cs, quality: .min): .init(
            startFret: 4,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 4, finger: .index),
                .D: .fretted(fret: 6, finger: .ring), .G: .fretted(fret: 6, finger: .pinky),
                .B: .fretted(fret: 5, finger: .middle), .highE: .fretted(fret: 4, finger: .index),
            ], barres: [.init(fret: 4, finger: .index, from: .A, to: .highE)]
        ),
        .init(root: .Cs, quality: .maj7): .init(
            startFret: 4,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 4, finger: .index),
                .D: .fretted(fret: 6, finger: .ring), .G: .fretted(fret: 5, finger: .middle),
                .B: .fretted(fret: 6, finger: .pinky), .highE: .fretted(fret: 4, finger: .index),
            ], barres: [.init(fret: 4, finger: .index, from: .A, to: .highE)]
        ),
        .init(root: .Cs, quality: .min7): .init(
            startFret: 4,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 4, finger: .index),
                .D: .fretted(fret: 6, finger: .ring), .G: .fretted(fret: 4, finger: .index),
                .B: .fretted(fret: 5, finger: .middle), .highE: .fretted(fret: 4, finger: .index),
            ], barres: [.init(fret: 4, finger: .index, from: .A, to: .highE)]
        ),
        .init(root: .Cs, quality: .dom7): .init(
            startFret: 4,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 4, finger: .index),
                .D: .fretted(fret: 6, finger: .ring), .G: .fretted(fret: 4, finger: .index),
                .B: .fretted(fret: 6, finger: .pinky), .highE: .fretted(fret: 4, finger: .index),
            ], barres: [.init(fret: 4, finger: .index, from: .A, to: .highE)]
        ),
        // C# Others
        .init(root: .Cs, quality: .maj9): .init(
            startFret: 3,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 4, finger: .middle),
                .D: .fretted(fret: 3, finger: .index), .G: .fretted(fret: 5, finger: .pinky),
                .B: .fretted(fret: 4, finger: .ring), .highE: .mute,
            ], barres: []
        ),
        .init(root: .Cs, quality: .dom9): .init(
            startFret: 3,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 4, finger: .middle),
                .D: .fretted(fret: 3, finger: .index), .G: .fretted(fret: 4, finger: .ring),
                .B: .fretted(fret: 4, finger: .pinky), .highE: .mute,
            ], barres: []
        ),
        .init(root: .Cs, quality: .dim): .init(
            startFret: 2,
            strings: [
                .lowE: .mute, .A: .mute, .D: .fretted(fret: 2, finger: .index),
                .G: .fretted(fret: 3, finger: .ring), .B: .fretted(fret: 2, finger: .middle),
                .highE: .mute,
            ], barres: []
        ),
        .init(root: .Cs, quality: .dim7): .init(
            startFret: 3,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 4, finger: .middle),
                .D: .fretted(fret: 5, finger: .ring), .G: .fretted(fret: 3, finger: .index),
                .B: .fretted(fret: 5, finger: .pinky), .highE: .mute,
            ], barres: []
        ),
        .init(root: .Cs, quality: .halfDim7): .init(
            startFret: 4,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 4, finger: .middle),
                .D: .fretted(fret: 5, finger: .ring), .G: .fretted(fret: 4, finger: .index),
                .B: .fretted(fret: 5, finger: .pinky), .highE: .mute,
            ], barres: []
        ),

        // MARK: - Root D (Open D)

        .init(root: .D, quality: .maj): .init(
            startFret: 0,
            strings: [
                .lowE: .mute, .A: .mute, .D: .open, .G: .fretted(fret: 2, finger: .index),
                .B: .fretted(fret: 3, finger: .ring), .highE: .fretted(fret: 2, finger: .middle),
            ], barres: []
        ),
        .init(root: .D, quality: .min): .init(
            startFret: 0,
            strings: [
                .lowE: .mute, .A: .mute, .D: .open, .G: .fretted(fret: 2, finger: .middle),
                .B: .fretted(fret: 3, finger: .ring), .highE: .fretted(fret: 1, finger: .index),
            ], barres: []
        ),
        .init(root: .D, quality: .maj7): .init(
            startFret: 0,
            strings: [
                .lowE: .mute, .A: .mute, .D: .open, .G: .fretted(fret: 2, finger: .index),
                .B: .fretted(fret: 2, finger: .index), .highE: .fretted(fret: 2, finger: .index),
            ], barres: [.init(fret: 2, finger: .index, from: .G, to: .highE)]
        ),
        .init(root: .D, quality: .min7): .init(
            startFret: 0,
            strings: [
                .lowE: .mute, .A: .mute, .D: .open, .G: .fretted(fret: 2, finger: .middle),
                .B: .fretted(fret: 1, finger: .index), .highE: .fretted(fret: 1, finger: .index),
            ], barres: [.init(fret: 1, finger: .index, from: .B, to: .highE)]
        ),
        .init(root: .D, quality: .dom7): .init(
            startFret: 0,
            strings: [
                .lowE: .mute, .A: .mute, .D: .open, .G: .fretted(fret: 2, finger: .middle),
                .B: .fretted(fret: 1, finger: .index), .highE: .fretted(fret: 2, finger: .ring),
            ], barres: []
        ),
        // D Others
        .init(root: .D, quality: .maj9): .init(
            startFret: 4,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 5, finger: .middle),
                .D: .fretted(fret: 4, finger: .index), .G: .fretted(fret: 6, finger: .pinky),
                .B: .fretted(fret: 5, finger: .ring), .highE: .mute,
            ], barres: []
        ),
        .init(root: .D, quality: .dom9): .init(
            startFret: 4,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 5, finger: .middle),
                .D: .fretted(fret: 4, finger: .index), .G: .fretted(fret: 5, finger: .ring),
                .B: .fretted(fret: 5, finger: .pinky), .highE: .mute,
            ], barres: []
        ),
        .init(root: .D, quality: .dim): .init(
            startFret: 3,
            strings: [
                .lowE: .mute, .A: .mute, .D: .fretted(fret: 3, finger: .index),
                .G: .fretted(fret: 4, finger: .ring), .B: .fretted(fret: 3, finger: .middle),
                .highE: .mute,
            ], barres: []
        ),
        .init(root: .D, quality: .dim7): .init(
            startFret: 4,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 5, finger: .middle),
                .D: .fretted(fret: 6, finger: .ring), .G: .fretted(fret: 4, finger: .index),
                .B: .fretted(fret: 6, finger: .pinky), .highE: .mute,
            ], barres: []
        ),
        .init(root: .D, quality: .halfDim7): .init(
            startFret: 5,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 5, finger: .middle),
                .D: .fretted(fret: 6, finger: .ring), .G: .fretted(fret: 5, finger: .index),
                .B: .fretted(fret: 6, finger: .pinky), .highE: .mute,
            ], barres: []
        ),

        // MARK: - Root D# (A Shape Barre at Fret 6)

        .init(root: .Ds, quality: .maj): .init(
            startFret: 6,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 6, finger: .index),
                .D: .fretted(fret: 8, finger: .middle), .G: .fretted(fret: 8, finger: .ring),
                .B: .fretted(fret: 8, finger: .pinky), .highE: .fretted(fret: 6, finger: .index),
            ], barres: [.init(fret: 6, finger: .index, from: .A, to: .highE)]
        ),
        .init(root: .Ds, quality: .min): .init(
            startFret: 6,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 6, finger: .index),
                .D: .fretted(fret: 8, finger: .ring), .G: .fretted(fret: 8, finger: .pinky),
                .B: .fretted(fret: 7, finger: .middle), .highE: .fretted(fret: 6, finger: .index),
            ], barres: [.init(fret: 6, finger: .index, from: .A, to: .highE)]
        ),
        .init(root: .Ds, quality: .maj7): .init(
            startFret: 6,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 6, finger: .index),
                .D: .fretted(fret: 8, finger: .ring), .G: .fretted(fret: 7, finger: .middle),
                .B: .fretted(fret: 8, finger: .pinky), .highE: .fretted(fret: 6, finger: .index),
            ], barres: [.init(fret: 6, finger: .index, from: .A, to: .highE)]
        ),
        .init(root: .Ds, quality: .min7): .init(
            startFret: 6,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 6, finger: .index),
                .D: .fretted(fret: 8, finger: .ring), .G: .fretted(fret: 6, finger: .index),
                .B: .fretted(fret: 7, finger: .middle), .highE: .fretted(fret: 6, finger: .index),
            ], barres: [.init(fret: 6, finger: .index, from: .A, to: .highE)]
        ),
        .init(root: .Ds, quality: .dom7): .init(
            startFret: 6,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 6, finger: .index),
                .D: .fretted(fret: 8, finger: .ring), .G: .fretted(fret: 6, finger: .index),
                .B: .fretted(fret: 8, finger: .pinky), .highE: .fretted(fret: 6, finger: .index),
            ], barres: [.init(fret: 6, finger: .index, from: .A, to: .highE)]
        ),
        // D# Others
        .init(root: .Ds, quality: .maj9): .init(
            startFret: 5,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 6, finger: .middle),
                .D: .fretted(fret: 5, finger: .index), .G: .fretted(fret: 7, finger: .pinky),
                .B: .fretted(fret: 6, finger: .ring), .highE: .mute,
            ], barres: []
        ),
        .init(root: .Ds, quality: .dom9): .init(
            startFret: 5,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 6, finger: .middle),
                .D: .fretted(fret: 5, finger: .index), .G: .fretted(fret: 6, finger: .ring),
                .B: .fretted(fret: 6, finger: .pinky), .highE: .mute,
            ], barres: []
        ),
        .init(root: .Ds, quality: .dim): .init(
            startFret: 4,
            strings: [
                .lowE: .mute, .A: .mute, .D: .fretted(fret: 4, finger: .index),
                .G: .fretted(fret: 5, finger: .ring), .B: .fretted(fret: 4, finger: .middle),
                .highE: .mute,
            ], barres: []
        ),
        .init(root: .Ds, quality: .dim7): .init(
            startFret: 5,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 6, finger: .middle),
                .D: .fretted(fret: 7, finger: .ring), .G: .fretted(fret: 5, finger: .index),
                .B: .fretted(fret: 7, finger: .pinky), .highE: .mute,
            ], barres: []
        ),
        .init(root: .Ds, quality: .halfDim7): .init(
            startFret: 6,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 6, finger: .middle),
                .D: .fretted(fret: 7, finger: .ring), .G: .fretted(fret: 6, finger: .index),
                .B: .fretted(fret: 7, finger: .pinky), .highE: .mute,
            ], barres: []
        ),

        // MARK: - Root E (Open E)

        .init(root: .E, quality: .maj): .init(
            startFret: 0,
            strings: [
                .lowE: .open, .A: .fretted(fret: 2, finger: .middle),
                .D: .fretted(fret: 2, finger: .ring), .G: .fretted(fret: 1, finger: .index),
                .B: .open, .highE: .open,
            ], barres: []
        ),
        .init(root: .E, quality: .min): .init(
            startFret: 0,
            strings: [
                .lowE: .open, .A: .fretted(fret: 2, finger: .middle),
                .D: .fretted(fret: 2, finger: .ring), .G: .open, .B: .open, .highE: .open,
            ], barres: []
        ),
        .init(root: .E, quality: .maj7): .init(
            startFret: 0,
            strings: [
                .lowE: .open, .A: .fretted(fret: 2, finger: .ring),
                .D: .fretted(fret: 1, finger: .index), .G: .fretted(fret: 1, finger: .middle),
                .B: .open, .highE: .open,
            ], barres: []
        ),
        .init(root: .E, quality: .min7): .init(
            startFret: 0,
            strings: [
                .lowE: .open, .A: .fretted(fret: 2, finger: .middle), .D: .open, .G: .open,
                .B: .open, .highE: .open,
            ], barres: []
        ),
        .init(root: .E, quality: .dom7): .init(
            startFret: 0,
            strings: [
                .lowE: .open, .A: .fretted(fret: 2, finger: .middle), .D: .open,
                .G: .fretted(fret: 1, finger: .index), .B: .open, .highE: .open,
            ], barres: []
        ),
        // E Others (Some moved forms)
        .init(root: .E, quality: .maj9): .init(
            startFret: 0,
            strings: [
                .lowE: .open, .A: .fretted(fret: 2, finger: .middle),
                .D: .fretted(fret: 1, finger: .index), .G: .fretted(fret: 1, finger: .index),
                .B: .open, .highE: .fretted(fret: 2, finger: .pinky),
            ], barres: []
        ),
        .init(root: .E, quality: .dom9): .init(
            startFret: 0,
            strings: [
                .lowE: .open, .A: .fretted(fret: 2, finger: .middle), .D: .open,
                .G: .fretted(fret: 1, finger: .index), .B: .fretted(fret: 3, finger: .ring),
                .highE: .fretted(fret: 2, finger: .ring),
            ], barres: []
        ),  // D7 shape moved up
        .init(root: .E, quality: .dim): .init(
            startFret: 0,
            strings: [
                .lowE: .open, .A: .fretted(fret: 1, finger: .index),
                .D: .fretted(fret: 2, finger: .ring), .G: .open, .B: .open, .highE: .open,
            ], barres: []
        ),  // E dim triad (rare)
        .init(root: .E, quality: .dim7): .init(
            startFret: 0,
            strings: [
                .lowE: .open, .A: .fretted(fret: 1, finger: .index),
                .D: .fretted(fret: 2, finger: .middle), .G: .open,
                .B: .fretted(fret: 2, finger: .ring), .highE: .open,
            ], barres: []
        ),
        .init(root: .E, quality: .halfDim7): .init(
            startFret: 0,
            strings: [
                .lowE: .open, .A: .fretted(fret: 1, finger: .index), .D: .open, .G: .open,
                .B: .open, .highE: .open,
            ], barres: []
        ),

        // MARK: - Root F (E Shape Barre at Fret 1)

        .init(root: .F, quality: .maj): .init(
            startFret: 1,
            strings: [
                .lowE: .fretted(fret: 1, finger: .index), .A: .fretted(fret: 3, finger: .ring),
                .D: .fretted(fret: 3, finger: .pinky), .G: .fretted(fret: 2, finger: .middle),
                .B: .fretted(fret: 1, finger: .index), .highE: .fretted(fret: 1, finger: .index),
            ], barres: [.init(fret: 1, finger: .index, from: .lowE, to: .highE)]
        ),
        .init(root: .F, quality: .min): .init(
            startFret: 1,
            strings: [
                .lowE: .fretted(fret: 1, finger: .index), .A: .fretted(fret: 3, finger: .ring),
                .D: .fretted(fret: 3, finger: .pinky), .G: .fretted(fret: 1, finger: .index),
                .B: .fretted(fret: 1, finger: .index), .highE: .fretted(fret: 1, finger: .index),
            ], barres: [.init(fret: 1, finger: .index, from: .lowE, to: .highE)]
        ),
        .init(root: .F, quality: .maj7): .init(
            startFret: 1,
            strings: [
                .lowE: .fretted(fret: 1, finger: .index), .A: .fretted(fret: 3, finger: .ring),
                .D: .fretted(fret: 2, finger: .middle), .G: .fretted(fret: 2, finger: .pinky),
                .B: .fretted(fret: 1, finger: .index), .highE: .fretted(fret: 1, finger: .index),
            ], barres: [.init(fret: 1, finger: .index, from: .lowE, to: .highE)]
        ),
        .init(root: .F, quality: .min7): .init(
            startFret: 1,
            strings: [
                .lowE: .fretted(fret: 1, finger: .index), .A: .fretted(fret: 3, finger: .ring),
                .D: .fretted(fret: 1, finger: .index), .G: .fretted(fret: 1, finger: .index),
                .B: .fretted(fret: 1, finger: .index), .highE: .fretted(fret: 1, finger: .index),
            ], barres: [.init(fret: 1, finger: .index, from: .lowE, to: .highE)]
        ),
        .init(root: .F, quality: .dom7): .init(
            startFret: 1,
            strings: [
                .lowE: .fretted(fret: 1, finger: .index), .A: .fretted(fret: 3, finger: .ring),
                .D: .fretted(fret: 1, finger: .index), .G: .fretted(fret: 2, finger: .middle),
                .B: .fretted(fret: 1, finger: .index), .highE: .fretted(fret: 1, finger: .index),
            ], barres: [.init(fret: 1, finger: .index, from: .lowE, to: .highE)]
        ),
        // F Others
        .init(root: .F, quality: .maj9): .init(
            startFret: 1,
            strings: [
                .lowE: .fretted(fret: 1, finger: .index), .A: .fretted(fret: 3, finger: .middle),
                .D: .fretted(fret: 2, finger: .index), .G: .fretted(fret: 2, finger: .index),
                .B: .fretted(fret: 1, finger: .index), .highE: .fretted(fret: 3, finger: .pinky),
            ], barres: [.init(fret: 1, finger: .index, from: .lowE, to: .B)]
        ),
        .init(root: .F, quality: .dom9): .init(
            startFret: 1,
            strings: [
                .lowE: .fretted(fret: 1, finger: .index), .A: .fretted(fret: 3, finger: .middle),
                .D: .fretted(fret: 1, finger: .index), .G: .fretted(fret: 2, finger: .ring),
                .B: .fretted(fret: 1, finger: .index), .highE: .fretted(fret: 3, finger: .pinky),
            ], barres: [.init(fret: 1, finger: .index, from: .lowE, to: .B)]
        ),
        .init(root: .F, quality: .dim): .init(
            startFret: 1,
            strings: [
                .lowE: .mute, .A: .mute, .D: .fretted(fret: 3, finger: .ring),
                .G: .fretted(fret: 1, finger: .index), .B: .mute, .highE: .mute,
            ], barres: []
        ),
        .init(root: .F, quality: .dim7): .init(
            startFret: 1,
            strings: [
                .lowE: .fretted(fret: 1, finger: .index), .A: .mute,
                .D: .fretted(fret: 1, finger: .middle), .G: .fretted(fret: 1, finger: .ring),
                .B: .fretted(fret: 1, finger: .pinky), .highE: .mute,
            ], barres: []
        ),  // E shape dim7
        .init(root: .F, quality: .halfDim7): .init(
            startFret: 1,
            strings: [
                .lowE: .fretted(fret: 1, finger: .index), .A: .fretted(fret: 1, finger: .index),
                .D: .fretted(fret: 1, finger: .index), .G: .fretted(fret: 1, finger: .index),
                .B: .fretted(fret: 1, finger: .index), .highE: .fretted(fret: 1, finger: .index),
            ], barres: [.init(fret: 1, finger: .index, from: .lowE, to: .highE)]
        ),

        // MARK: - Root F# (E Shape Barre at Fret 2)

        .init(root: .Fs, quality: .maj): .init(
            startFret: 2,
            strings: [
                .lowE: .fretted(fret: 2, finger: .index), .A: .fretted(fret: 4, finger: .ring),
                .D: .fretted(fret: 4, finger: .pinky), .G: .fretted(fret: 3, finger: .middle),
                .B: .fretted(fret: 2, finger: .index), .highE: .fretted(fret: 2, finger: .index),
            ], barres: [.init(fret: 2, finger: .index, from: .lowE, to: .highE)]
        ),
        .init(root: .Fs, quality: .min): .init(
            startFret: 2,
            strings: [
                .lowE: .fretted(fret: 2, finger: .index), .A: .fretted(fret: 4, finger: .ring),
                .D: .fretted(fret: 4, finger: .pinky), .G: .fretted(fret: 2, finger: .index),
                .B: .fretted(fret: 2, finger: .index), .highE: .fretted(fret: 2, finger: .index),
            ], barres: [.init(fret: 2, finger: .index, from: .lowE, to: .highE)]
        ),
        .init(root: .Fs, quality: .maj7): .init(
            startFret: 2,
            strings: [
                .lowE: .fretted(fret: 2, finger: .index), .A: .fretted(fret: 4, finger: .ring),
                .D: .fretted(fret: 3, finger: .middle), .G: .fretted(fret: 3, finger: .pinky),
                .B: .fretted(fret: 2, finger: .index), .highE: .fretted(fret: 2, finger: .index),
            ], barres: [.init(fret: 2, finger: .index, from: .lowE, to: .highE)]
        ),
        .init(root: .Fs, quality: .min7): .init(
            startFret: 2,
            strings: [
                .lowE: .fretted(fret: 2, finger: .index), .A: .fretted(fret: 4, finger: .ring),
                .D: .fretted(fret: 2, finger: .index), .G: .fretted(fret: 2, finger: .index),
                .B: .fretted(fret: 2, finger: .index), .highE: .fretted(fret: 2, finger: .index),
            ], barres: [.init(fret: 2, finger: .index, from: .lowE, to: .highE)]
        ),
        .init(root: .Fs, quality: .dom7): .init(
            startFret: 2,
            strings: [
                .lowE: .fretted(fret: 2, finger: .index), .A: .fretted(fret: 4, finger: .ring),
                .D: .fretted(fret: 2, finger: .index), .G: .fretted(fret: 3, finger: .middle),
                .B: .fretted(fret: 2, finger: .index), .highE: .fretted(fret: 2, finger: .index),
            ], barres: [.init(fret: 2, finger: .index, from: .lowE, to: .highE)]
        ),
        // F# Others (Simplified Barre Logic)
        .init(root: .Fs, quality: .maj9): .init(
            startFret: 2,
            strings: [
                .lowE: .fretted(fret: 2, finger: .index), .A: .fretted(fret: 4, finger: .middle),
                .D: .fretted(fret: 3, finger: .index), .G: .fretted(fret: 3, finger: .index),
                .B: .fretted(fret: 2, finger: .index), .highE: .fretted(fret: 4, finger: .pinky),
            ], barres: [.init(fret: 2, finger: .index, from: .lowE, to: .B)]
        ),
        .init(root: .Fs, quality: .dom9): .init(
            startFret: 2,
            strings: [
                .lowE: .fretted(fret: 2, finger: .index), .A: .fretted(fret: 4, finger: .middle),
                .D: .fretted(fret: 2, finger: .index), .G: .fretted(fret: 3, finger: .ring),
                .B: .fretted(fret: 2, finger: .index), .highE: .fretted(fret: 4, finger: .pinky),
            ], barres: [.init(fret: 2, finger: .index, from: .lowE, to: .B)]
        ),
        .init(root: .Fs, quality: .dim): .init(
            startFret: 1,
            strings: [
                .lowE: .mute, .A: .mute, .D: .fretted(fret: 1, finger: .index),
                .G: .fretted(fret: 2, finger: .ring), .B: .fretted(fret: 1, finger: .middle),
                .highE: .mute,
            ], barres: []
        ),  // C Shape Dim
        .init(root: .Fs, quality: .dim7): .init(
            startFret: 2,
            strings: [
                .lowE: .fretted(fret: 2, finger: .index), .A: .mute,
                .D: .fretted(fret: 2, finger: .middle), .G: .fretted(fret: 2, finger: .ring),
                .B: .fretted(fret: 2, finger: .pinky), .highE: .mute,
            ], barres: []
        ),
        .init(root: .Fs, quality: .halfDim7): .init(
            startFret: 2,
            strings: [
                .lowE: .fretted(fret: 2, finger: .index), .A: .fretted(fret: 2, finger: .index),
                .D: .fretted(fret: 2, finger: .index), .G: .fretted(fret: 2, finger: .index),
                .B: .fretted(fret: 2, finger: .index), .highE: .fretted(fret: 2, finger: .index),
            ], barres: [.init(fret: 2, finger: .index, from: .lowE, to: .highE)]
        ),

        // MARK: - Root G (Open G & E Shape Barre Fret 3)

        .init(root: .G, quality: .maj): .init(
            startFret: 0,
            strings: [
                .lowE: .fretted(fret: 3, finger: .ring), .A: .fretted(fret: 2, finger: .middle),
                .D: .open, .G: .open, .B: .open, .highE: .fretted(fret: 3, finger: .pinky),
            ], barres: []
        ),
        .init(root: .G, quality: .min): .init(
            startFret: 3,
            strings: [
                .lowE: .fretted(fret: 3, finger: .index), .A: .fretted(fret: 5, finger: .ring),
                .D: .fretted(fret: 5, finger: .pinky), .G: .fretted(fret: 3, finger: .index),
                .B: .fretted(fret: 3, finger: .index), .highE: .fretted(fret: 3, finger: .index),
            ], barres: [.init(fret: 3, finger: .index, from: .lowE, to: .highE)]
        ),
        .init(root: .G, quality: .maj7): .init(
            startFret: 0,
            strings: [
                .lowE: .fretted(fret: 3, finger: .ring), .A: .fretted(fret: 2, finger: .middle),
                .D: .open, .G: .open, .B: .open, .highE: .fretted(fret: 2, finger: .index),
            ], barres: []
        ),
        .init(root: .G, quality: .min7): .init(
            startFret: 3,
            strings: [
                .lowE: .fretted(fret: 3, finger: .index), .A: .fretted(fret: 5, finger: .ring),
                .D: .fretted(fret: 3, finger: .index), .G: .fretted(fret: 3, finger: .index),
                .B: .fretted(fret: 3, finger: .index), .highE: .fretted(fret: 3, finger: .index),
            ], barres: [.init(fret: 3, finger: .index, from: .lowE, to: .highE)]
        ),
        .init(root: .G, quality: .dom7): .init(
            startFret: 0,
            strings: [
                .lowE: .fretted(fret: 3, finger: .ring), .A: .fretted(fret: 2, finger: .middle),
                .D: .open, .G: .open, .B: .open, .highE: .fretted(fret: 1, finger: .index),
            ], barres: []
        ),
        // G Others
        .init(root: .G, quality: .maj9): .init(
            startFret: 0,
            strings: [
                .lowE: .fretted(fret: 3, finger: .middle), .A: .mute, .D: .open,
                .G: .fretted(fret: 2, finger: .index), .B: .open,
                .highE: .fretted(fret: 2, finger: .index),
            ], barres: []
        ),
        .init(root: .G, quality: .dom9): .init(
            startFret: 3,
            strings: [
                .lowE: .fretted(fret: 3, finger: .index), .A: .fretted(fret: 5, finger: .middle),
                .D: .fretted(fret: 3, finger: .index), .G: .fretted(fret: 4, finger: .ring),
                .B: .fretted(fret: 3, finger: .index), .highE: .fretted(fret: 5, finger: .pinky),
            ], barres: [.init(fret: 3, finger: .index, from: .lowE, to: .B)]
        ),
        .init(root: .G, quality: .dim): .init(
            startFret: 2,
            strings: [
                .lowE: .mute, .A: .mute, .D: .fretted(fret: 2, finger: .index),
                .G: .fretted(fret: 3, finger: .ring), .B: .fretted(fret: 2, finger: .middle),
                .highE: .mute,
            ], barres: []
        ),
        .init(root: .G, quality: .dim7): .init(
            startFret: 2,
            strings: [
                .lowE: .fretted(fret: 3, finger: .middle), .A: .mute,
                .D: .fretted(fret: 3, finger: .ring), .G: .fretted(fret: 3, finger: .pinky),
                .B: .fretted(fret: 2, finger: .index), .highE: .mute,
            ], barres: []
        ),
        .init(root: .G, quality: .halfDim7): .init(
            startFret: 3,
            strings: [
                .lowE: .fretted(fret: 3, finger: .index), .A: .fretted(fret: 3, finger: .index),
                .D: .fretted(fret: 3, finger: .index), .G: .fretted(fret: 3, finger: .index),
                .B: .fretted(fret: 3, finger: .index), .highE: .fretted(fret: 3, finger: .index),
            ], barres: [.init(fret: 3, finger: .index, from: .lowE, to: .highE)]
        ),

        // MARK: - Root G# (E Shape Barre at Fret 4)

        .init(root: .Gs, quality: .maj): .init(
            startFret: 4,
            strings: [
                .lowE: .fretted(fret: 4, finger: .index), .A: .fretted(fret: 6, finger: .ring),
                .D: .fretted(fret: 6, finger: .pinky), .G: .fretted(fret: 5, finger: .middle),
                .B: .fretted(fret: 4, finger: .index), .highE: .fretted(fret: 4, finger: .index),
            ], barres: [.init(fret: 4, finger: .index, from: .lowE, to: .highE)]
        ),
        .init(root: .Gs, quality: .min): .init(
            startFret: 4,
            strings: [
                .lowE: .fretted(fret: 4, finger: .index), .A: .fretted(fret: 6, finger: .ring),
                .D: .fretted(fret: 6, finger: .pinky), .G: .fretted(fret: 4, finger: .index),
                .B: .fretted(fret: 4, finger: .index), .highE: .fretted(fret: 4, finger: .index),
            ], barres: [.init(fret: 4, finger: .index, from: .lowE, to: .highE)]
        ),
        .init(root: .Gs, quality: .maj7): .init(
            startFret: 4,
            strings: [
                .lowE: .fretted(fret: 4, finger: .index), .A: .fretted(fret: 6, finger: .ring),
                .D: .fretted(fret: 5, finger: .middle), .G: .fretted(fret: 5, finger: .pinky),
                .B: .fretted(fret: 4, finger: .index), .highE: .fretted(fret: 4, finger: .index),
            ], barres: [.init(fret: 4, finger: .index, from: .lowE, to: .highE)]
        ),
        .init(root: .Gs, quality: .min7): .init(
            startFret: 4,
            strings: [
                .lowE: .fretted(fret: 4, finger: .index), .A: .fretted(fret: 6, finger: .ring),
                .D: .fretted(fret: 4, finger: .index), .G: .fretted(fret: 4, finger: .index),
                .B: .fretted(fret: 4, finger: .index), .highE: .fretted(fret: 4, finger: .index),
            ], barres: [.init(fret: 4, finger: .index, from: .lowE, to: .highE)]
        ),
        .init(root: .Gs, quality: .dom7): .init(
            startFret: 4,
            strings: [
                .lowE: .fretted(fret: 4, finger: .index), .A: .fretted(fret: 6, finger: .ring),
                .D: .fretted(fret: 4, finger: .index), .G: .fretted(fret: 5, finger: .middle),
                .B: .fretted(fret: 4, finger: .index), .highE: .fretted(fret: 4, finger: .index),
            ], barres: [.init(fret: 4, finger: .index, from: .lowE, to: .highE)]
        ),
        // G# Others
        .init(root: .Gs, quality: .maj9): .init(
            startFret: 4,
            strings: [
                .lowE: .fretted(fret: 4, finger: .index), .A: .fretted(fret: 6, finger: .middle),
                .D: .fretted(fret: 5, finger: .index), .G: .fretted(fret: 5, finger: .index),
                .B: .fretted(fret: 4, finger: .index), .highE: .fretted(fret: 6, finger: .pinky),
            ], barres: [.init(fret: 4, finger: .index, from: .lowE, to: .B)]
        ),
        .init(root: .Gs, quality: .dom9): .init(
            startFret: 4,
            strings: [
                .lowE: .fretted(fret: 4, finger: .index), .A: .fretted(fret: 6, finger: .middle),
                .D: .fretted(fret: 4, finger: .index), .G: .fretted(fret: 5, finger: .ring),
                .B: .fretted(fret: 4, finger: .index), .highE: .fretted(fret: 6, finger: .pinky),
            ], barres: [.init(fret: 4, finger: .index, from: .lowE, to: .B)]
        ),
        .init(root: .Gs, quality: .dim): .init(
            startFret: 3,
            strings: [
                .lowE: .mute, .A: .mute, .D: .fretted(fret: 3, finger: .index),
                .G: .fretted(fret: 4, finger: .ring), .B: .fretted(fret: 3, finger: .middle),
                .highE: .mute,
            ], barres: []
        ),
        .init(root: .Gs, quality: .dim7): .init(
            startFret: 3,
            strings: [
                .lowE: .fretted(fret: 4, finger: .middle), .A: .mute,
                .D: .fretted(fret: 4, finger: .ring), .G: .fretted(fret: 4, finger: .pinky),
                .B: .fretted(fret: 3, finger: .index), .highE: .mute,
            ], barres: []
        ),
        .init(root: .Gs, quality: .halfDim7): .init(
            startFret: 4,
            strings: [
                .lowE: .fretted(fret: 4, finger: .index), .A: .fretted(fret: 4, finger: .index),
                .D: .fretted(fret: 4, finger: .index), .G: .fretted(fret: 4, finger: .index),
                .B: .fretted(fret: 4, finger: .index), .highE: .fretted(fret: 4, finger: .index),
            ], barres: [.init(fret: 4, finger: .index, from: .lowE, to: .highE)]
        ),

        // MARK: - Root A (Open A)

        .init(root: .A, quality: .maj): .init(
            startFret: 0,
            strings: [
                .lowE: .mute, .A: .open, .D: .fretted(fret: 2, finger: .index),
                .G: .fretted(fret: 2, finger: .middle), .B: .fretted(fret: 2, finger: .ring),
                .highE: .open,
            ], barres: []
        ),
        .init(root: .A, quality: .min): .init(
            startFret: 0,
            strings: [
                .lowE: .mute, .A: .open, .D: .fretted(fret: 2, finger: .middle),
                .G: .fretted(fret: 2, finger: .ring), .B: .fretted(fret: 1, finger: .index),
                .highE: .open,
            ], barres: []
        ),
        .init(root: .A, quality: .maj7): .init(
            startFret: 0,
            strings: [
                .lowE: .mute, .A: .open, .D: .fretted(fret: 2, finger: .middle),
                .G: .fretted(fret: 1, finger: .index), .B: .fretted(fret: 2, finger: .ring),
                .highE: .open,
            ], barres: []
        ),
        .init(root: .A, quality: .min7): .init(
            startFret: 0,
            strings: [
                .lowE: .mute, .A: .open, .D: .fretted(fret: 2, finger: .middle), .G: .open,
                .B: .fretted(fret: 1, finger: .index), .highE: .open,
            ], barres: []
        ),
        .init(root: .A, quality: .dom7): .init(
            startFret: 0,
            strings: [
                .lowE: .mute, .A: .open, .D: .fretted(fret: 2, finger: .middle), .G: .open,
                .B: .fretted(fret: 2, finger: .ring), .highE: .open,
            ], barres: []
        ),
        // A Others
        .init(root: .A, quality: .maj9): .init(
            startFret: 0,
            strings: [
                .lowE: .mute, .A: .open, .D: .fretted(fret: 2, finger: .index),
                .G: .fretted(fret: 1, finger: .index), .B: .open,
                .highE: .fretted(fret: 2, finger: .index),
            ], barres: []
        ),  // Hard to play open, often uses barre. Used simplified open here.
        .init(root: .A, quality: .dom9): .init(
            startFret: 0,
            strings: [
                .lowE: .mute, .A: .open, .D: .fretted(fret: 2, finger: .index), .G: .open,
                .B: .fretted(fret: 2, finger: .ring), .highE: .open,
            ], barres: []
        ),
        .init(root: .A, quality: .dim): .init(
            startFret: 4,
            strings: [
                .lowE: .mute, .A: .mute, .D: .fretted(fret: 4, finger: .index),
                .G: .fretted(fret: 5, finger: .ring), .B: .fretted(fret: 4, finger: .middle),
                .highE: .mute,
            ], barres: []
        ),
        .init(root: .A, quality: .dim7): .init(
            startFret: 4,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 5, finger: .middle),
                .D: .fretted(fret: 6, finger: .ring), .G: .fretted(fret: 4, finger: .index),
                .B: .fretted(fret: 6, finger: .pinky), .highE: .mute,
            ], barres: []
        ),  // Dim7 movable
        .init(root: .A, quality: .halfDim7): .init(
            startFret: 5,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 5, finger: .middle),
                .D: .fretted(fret: 6, finger: .ring), .G: .fretted(fret: 5, finger: .index),
                .B: .fretted(fret: 6, finger: .pinky), .highE: .mute,
            ], barres: []
        ),  // m7b5 movable

        // MARK: - Root A# (A Shape Barre at Fret 1)

        .init(root: .As, quality: .maj): .init(
            startFret: 1,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 1, finger: .index),
                .D: .fretted(fret: 3, finger: .middle), .G: .fretted(fret: 3, finger: .ring),
                .B: .fretted(fret: 3, finger: .pinky), .highE: .fretted(fret: 1, finger: .index),
            ], barres: [.init(fret: 1, finger: .index, from: .A, to: .highE)]
        ),
        .init(root: .As, quality: .min): .init(
            startFret: 1,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 1, finger: .index),
                .D: .fretted(fret: 3, finger: .ring), .G: .fretted(fret: 3, finger: .pinky),
                .B: .fretted(fret: 2, finger: .middle), .highE: .fretted(fret: 1, finger: .index),
            ], barres: [.init(fret: 1, finger: .index, from: .A, to: .highE)]
        ),
        .init(root: .As, quality: .maj7): .init(
            startFret: 1,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 1, finger: .index),
                .D: .fretted(fret: 3, finger: .ring), .G: .fretted(fret: 2, finger: .middle),
                .B: .fretted(fret: 3, finger: .pinky), .highE: .fretted(fret: 1, finger: .index),
            ], barres: [.init(fret: 1, finger: .index, from: .A, to: .highE)]
        ),
        .init(root: .As, quality: .min7): .init(
            startFret: 1,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 1, finger: .index),
                .D: .fretted(fret: 3, finger: .ring), .G: .fretted(fret: 1, finger: .index),
                .B: .fretted(fret: 2, finger: .middle), .highE: .fretted(fret: 1, finger: .index),
            ], barres: [.init(fret: 1, finger: .index, from: .A, to: .highE)]
        ),
        .init(root: .As, quality: .dom7): .init(
            startFret: 1,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 1, finger: .index),
                .D: .fretted(fret: 3, finger: .ring), .G: .fretted(fret: 1, finger: .index),
                .B: .fretted(fret: 3, finger: .pinky), .highE: .fretted(fret: 1, finger: .index),
            ], barres: [.init(fret: 1, finger: .index, from: .A, to: .highE)]
        ),
        // A# Others
        .init(root: .As, quality: .maj9): .init(
            startFret: 1,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 1, finger: .middle),
                .D: .fretted(fret: 0, finger: .index), .G: .fretted(fret: 2, finger: .pinky),
                .B: .fretted(fret: 1, finger: .ring), .highE: .mute,
            ], barres: []
        ),
        .init(root: .As, quality: .dom9): .init(
            startFret: 1,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 1, finger: .middle),
                .D: .fretted(fret: 0, finger: .index), .G: .fretted(fret: 1, finger: .ring),
                .B: .fretted(fret: 1, finger: .pinky), .highE: .mute,
            ], barres: []
        ),
        .init(root: .As, quality: .dim): .init(
            startFret: 5,
            strings: [
                .lowE: .mute, .A: .mute, .D: .fretted(fret: 5, finger: .index),
                .G: .fretted(fret: 6, finger: .ring), .B: .fretted(fret: 5, finger: .middle),
                .highE: .mute,
            ], barres: []
        ),
        .init(root: .As, quality: .dim7): .init(
            startFret: 5,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 6, finger: .middle),
                .D: .fretted(fret: 7, finger: .ring), .G: .fretted(fret: 5, finger: .index),
                .B: .fretted(fret: 7, finger: .pinky), .highE: .mute,
            ], barres: []
        ),
        .init(root: .As, quality: .halfDim7): .init(
            startFret: 6,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 6, finger: .middle),
                .D: .fretted(fret: 7, finger: .ring), .G: .fretted(fret: 6, finger: .index),
                .B: .fretted(fret: 7, finger: .pinky), .highE: .mute,
            ], barres: []
        ),

        // MARK: - Root B (A Shape Barre at Fret 2)

        .init(root: .B, quality: .maj): .init(
            startFret: 2,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 2, finger: .index),
                .D: .fretted(fret: 4, finger: .middle), .G: .fretted(fret: 4, finger: .ring),
                .B: .fretted(fret: 4, finger: .pinky), .highE: .fretted(fret: 2, finger: .index),
            ], barres: [.init(fret: 2, finger: .index, from: .A, to: .highE)]
        ),
        .init(root: .B, quality: .min): .init(
            startFret: 2,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 2, finger: .index),
                .D: .fretted(fret: 4, finger: .ring), .G: .fretted(fret: 4, finger: .pinky),
                .B: .fretted(fret: 3, finger: .middle), .highE: .fretted(fret: 2, finger: .index),
            ], barres: [.init(fret: 2, finger: .index, from: .A, to: .highE)]
        ),
        .init(root: .B, quality: .maj7): .init(
            startFret: 2,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 2, finger: .index),
                .D: .fretted(fret: 4, finger: .ring), .G: .fretted(fret: 3, finger: .middle),
                .B: .fretted(fret: 4, finger: .pinky), .highE: .fretted(fret: 2, finger: .index),
            ], barres: [.init(fret: 2, finger: .index, from: .A, to: .highE)]
        ),
        .init(root: .B, quality: .min7): .init(
            startFret: 2,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 2, finger: .index),
                .D: .fretted(fret: 4, finger: .ring), .G: .fretted(fret: 2, finger: .index),
                .B: .fretted(fret: 3, finger: .middle), .highE: .fretted(fret: 2, finger: .index),
            ], barres: [.init(fret: 2, finger: .index, from: .A, to: .highE)]
        ),
        .init(root: .B, quality: .dom7): .init(
            startFret: 2,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 2, finger: .index),
                .D: .fretted(fret: 4, finger: .ring), .G: .fretted(fret: 2, finger: .index),
                .B: .fretted(fret: 4, finger: .pinky), .highE: .fretted(fret: 2, finger: .index),
            ], barres: [.init(fret: 2, finger: .index, from: .A, to: .highE)]
        ),
        // B Others
        .init(root: .B, quality: .maj9): .init(
            startFret: 2,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 2, finger: .middle),
                .D: .fretted(fret: 1, finger: .index), .G: .fretted(fret: 3, finger: .pinky),
                .B: .fretted(fret: 2, finger: .ring), .highE: .mute,
            ], barres: []
        ),
        .init(root: .B, quality: .dom9): .init(
            startFret: 2,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 2, finger: .middle),
                .D: .fretted(fret: 1, finger: .index), .G: .fretted(fret: 2, finger: .ring),
                .B: .fretted(fret: 2, finger: .pinky), .highE: .mute,
            ], barres: []
        ),
        .init(root: .B, quality: .dim): .init(
            startFret: 1,
            strings: [
                .lowE: .mute, .A: .mute, .D: .fretted(fret: 0, finger: .index),
                .G: .fretted(fret: 1, finger: .ring), .B: .open, .highE: .mute,
            ], barres: []
        ),  // Open B dim
        .init(root: .B, quality: .dim7): .init(
            startFret: 1,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 2, finger: .middle),
                .D: .fretted(fret: 3, finger: .ring), .G: .fretted(fret: 1, finger: .index),
                .B: .fretted(fret: 3, finger: .pinky), .highE: .mute,
            ], barres: []
        ),
        .init(root: .B, quality: .halfDim7): .init(
            startFret: 2,
            strings: [
                .lowE: .mute, .A: .fretted(fret: 2, finger: .middle),
                .D: .fretted(fret: 3, finger: .ring), .G: .fretted(fret: 2, finger: .index),
                .B: .fretted(fret: 3, finger: .pinky), .highE: .mute,
            ], barres: []
        ),
    ]
}
