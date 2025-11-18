//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftData

enum ScoreSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }
    static var models: [any PersistentModel.Type] {
        [Score.self]
    }

    @Model
    final class Score {
        @Attribute(.unique) var id: UUID
        var title: String
        var key: Key
        var audioFileName: String
        var totalDuration: TimeInterval
        var createdAt: Date
        var updatedAt: Date
        var notes: [Note]
        var chordCells: [ChordCell]
        var audioLevels: [Float]

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
            audioLevels: [Float]
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
        }
    }

    struct ChordCell: Codable {
        var chord: Chord?
        var chordCandidates: [Chord]
        var startTime: TimeInterval
    }

    struct Chord: Codable {
        let root: NoteName
        let quality: ChordQuality
    }

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

    struct Key: Codable {
        let root: NoteName
    }

    struct Note: Codable {
        let name: NoteName
        let octave: Int
        let startTime: TimeInterval
        let duration: TimeInterval
    }

    enum NoteName: Codable {
        case C
        case Cs
        case Db
        case D
        case Ds
        case Eb
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
}

extension ScoreSchemaV1.NoteName {
    func toDomain() -> NoteName {
        switch self {
        case .C: return .C
        case .Cs: return .Cs
        case .Db: return .Db
        case .D: return .D
        case .Ds: return .Ds
        case .Eb: return .Eb
        case .E: return .E
        case .Fb: return .Fb
        case .F: return .F
        case .Fs: return .Fs
        case .Gb: return .Gb
        case .G: return .G
        case .Gs: return .Gs
        case .Ab: return .Ab
        case .A: return .A
        case .As: return .As
        case .Bb: return .Bb
        case .B: return .B
        }
    }
}

extension ScoreSchemaV1.ChordQuality {
    func toDomain() -> ChordQuality {
        switch self {
        case .maj: return .maj
        case .maj7: return .maj7
        case .maj9: return .maj9
        case .min: return .min
        case .min7: return .min7
        case .dom7: return .dom7
        case .dom9: return .dom9
        case .dim: return .dim
        case .dim7: return .dim7
        case .halfDim7: return .halfDim7
        }
    }
}

extension ScoreSchemaV1.Key {
    func toDomain() -> Key {
        Key(root: self.root.toDomain())
    }
}

extension ScoreSchemaV1.Chord {
    func toDomain() -> Chord {
        Chord(root: self.root.toDomain(), quality: self.quality.toDomain())
    }
}

extension ScoreSchemaV1.Note {
    func toDomain() -> Note {
        Note(
            name: self.name.toDomain(),
            octave: self.octave,
            startTime: self.startTime,
            duration: self.duration
        )
    }
}

extension ScoreSchemaV1.ChordCell {
    func toDomain() -> ChordCell {
        ChordCell(
            chord: self.chord?.toDomain(),
            chordCandidates: self.chordCandidates.map { $0.toDomain() },
            startTime: self.startTime
        )
    }
}
