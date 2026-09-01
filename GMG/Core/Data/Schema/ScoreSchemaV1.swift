//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftData

enum ScoreSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [Score.self, ChordCell.self, Chord.self, Key.self, Note.self]
    }

    @Model
    final class Score {
        @Attribute(.unique) var id: UUID = UUID()
        var title: String = ""
        var key: Key = Key(root: .C)
        var audioFileName: String = ""
        var totalDuration: TimeInterval = TimeInterval.zero
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now
        @Relationship(deleteRule: .cascade) var notes: [Note] = []
        @Relationship(deleteRule: .cascade) var chordCells: [ChordCell] = []
        var audioLevels: [Float] = []
        var isDeleted: Bool = false

        init(
            id: UUID,
            title: String,
            key: Key,
            audioFileName: String,
            totalDuration: TimeInterval,
            createdAt: Date,
            updatedAt: Date,
            notes: [Note],
            chordCells: [ChordCell],
            audioLevels: [Float],
            isDeleted: Bool
        ) {
            self.id = id
            self.title = title
            self.key = key
            self.audioFileName = audioFileName
            self.totalDuration = totalDuration
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.notes = notes
            self.chordCells = chordCells
            self.audioLevels = audioLevels
            self.isDeleted = isDeleted
        }
    }

    @Model
    class ChordCell {
        @Relationship(deleteRule: .cascade) var chord: Chord? = nil
        @Relationship(deleteRule: .cascade) var chordCandidates: [ChordCandidate] = []
        var startTime: TimeInterval = TimeInterval.zero
        var duration: TimeInterval = TimeInterval.zero

        init(
            chord: Chord?,
            chordCandidates: [ChordCandidate],
            startTime: TimeInterval,
            duration: TimeInterval
        ) {
            self.chord = chord
            self.chordCandidates = chordCandidates
            self.startTime = startTime
            self.duration = duration
        }
    }

    @Model
    class ChordCandidate {
        var order: Int = 0
        @Relationship(deleteRule: .cascade) var chord: Chord = Chord(root: .C, quality: .maj)

        init(
            order: Int,
            chord: Chord
        ) {
            self.order = order
            self.chord = chord
        }
    }

    @Model
    class Chord {
        var rootRaw: NoteName.RawValue = NoteName.C.rawValue
        var root: NoteName {
            get { .init(rawValue: rootRaw) ?? .C }
            set { rootRaw = newValue.rawValue }
        }
        var qualityRaw: ChordQuality.RawValue = ChordQuality.maj.rawValue
        var quality: ChordQuality {
            get { .init(rawValue: qualityRaw) ?? .maj }
            set { qualityRaw = newValue.rawValue }
        }

        init(root: NoteName, quality: ChordQuality) {
            self.root = root
            self.quality = quality
        }
    }

    enum ChordQuality: String {
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
        // Added with the tick-grid model. Raw values are new strings, so rows
        // written before this stay readable.
        case sus4
        case aug
    }

    @Model
    class Key {
        var rootRaw: NoteName.RawValue = NoteName.C.rawValue
        var root: NoteName {
            get { .init(rawValue: rootRaw) ?? .C }
            set { rootRaw = newValue.rawValue }
        }

        init(root: NoteName) {
            self.root = root
        }
    }

    @Model
    class Note {
        var nameRaw: NoteName.RawValue = NoteName.C.rawValue
        var name: NoteName {
            get { .init(rawValue: nameRaw) ?? .C }
            set { nameRaw = newValue.rawValue }
        }
        var octave: Int = Int.zero
        var startTime: TimeInterval = TimeInterval.zero
        var duration: TimeInterval = TimeInterval.zero

        init(name: NoteName, octave: Int, startTime: TimeInterval, duration: TimeInterval) {
            self.name = name
            self.octave = octave
            self.startTime = startTime
            self.duration = duration
        }
    }

    enum NoteName: String {
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
}
