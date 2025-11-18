//  Copyright © 2025 ADA 4th GMG. All rights reserved.
import Foundation
import SwiftData

struct ScoreShemaV1Backup: Sendable {
    var id: UUID
    var title: String
    var key: Key
    var audioFileName: String
    var totalDuration: TimeInterval
    var createdAt: Date
    var updatedAt: Date
    var notes: [Note]
    var chordCells: [ChordCell]
    var audioLevels: [Float]
}

enum ScoreMigrationPlans: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ScoreSchemaV1.self, ScoreSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    nonisolated(unsafe) static var scoreSchemaV1Backup: ScoreShemaV1Backup? = nil

    //    static let migrateV1toV2: MigrationStage = .lightweight(fromVersion: ScoreSchemaV1.self, toVersion: ScoreSchemaV2.self)
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: ScoreSchemaV1.self,
        toVersion: ScoreSchemaV2.self,
        willMigrate: { context in
            if let oldScore = (try? context.fetch(FetchDescriptor<ScoreSchemaV1.Score>()))?.first {
                scoreSchemaV1Backup = ScoreShemaV1Backup(
                    id: oldScore.id,
                    title: oldScore.title,
                    key: oldScore.key.toDomain(),
                    audioFileName: oldScore.audioFileName,
                    totalDuration: oldScore.totalDuration,
                    createdAt: oldScore.createdAt,
                    updatedAt: oldScore.updatedAt,
                    notes: oldScore.notes.map { $0.toDomain() },
                    chordCells: oldScore.chordCells.map { $0.toDomain() },
                    audioLevels: oldScore.audioLevels
                )
            }
        },
        didMigrate: { context in
            if let newScore = (try? context.fetch(FetchDescriptor<ScoreSchemaV2.Score>()))?.first {
                if let backup = scoreSchemaV1Backup {
                    newScore.chordCells = backup.chordCells.map { cell in
                        let schemaChord: ScoreSchemaV2.Chord? = cell.chord.flatMap { domainChord in
                            guard
                                let root = ScoreSchemaV2.NoteName(fromDomain: domainChord.root),
                                let quality = ScoreSchemaV2.ChordQuality(
                                    fromDomain: domainChord.quality)
                            else { return nil }
                            return ScoreSchemaV2.Chord(root: root, quality: quality)
                        }

                        let schemaCandidates: [ScoreSchemaV2.Chord] = cell.chordCandidates
                            .compactMap { candidate in
                                guard
                                    let root = ScoreSchemaV2.NoteName(fromDomain: candidate.root),
                                    let quality = ScoreSchemaV2.ChordQuality(
                                        fromDomain: candidate.quality)
                                else { return nil }
                                return ScoreSchemaV2.Chord(root: root, quality: quality)
                            }

                        return ScoreSchemaV2.ChordCell(
                            chord: schemaChord,
                            chordCandidates: schemaCandidates,
                            startTime: cell.startTime,
                            duration: cell.duration
                        )
                    }

                    try context.save()
                }
            }
        }
    )
}
