//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftData

enum ScoreSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(2, 0, 0)
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
        var duration: TimeInterval
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
