//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftData

protocol ScoreRepository {
    func fetch() throws -> [Score]
    func fetch(id: UUID) throws -> Score?
    func insert(_ score: Score) throws
    func update(_ score: Score) throws
    func delete(_ score: Score) throws
}

final class SwiftDataScoreRepository: ScoreRepository {
    private let storage: SwiftDataStorage

    private var context: ModelContext { storage.context }

    init(storage: SwiftDataStorage) {
        self.storage = storage
    }

    func fetch() throws -> [Score] {
        /// Soft Delete 되지 않은 Score만 가져오기
        let predicate: Predicate<ScoreSchema.Score> = #Predicate { $0.isDeleted == false }
        let fetchDescriptor: FetchDescriptor<ScoreSchema.Score> = .init(predicate: predicate)
        let scorePersitences: [ScoreSchema.Score] = try context.fetch(fetchDescriptor)

        let scores: [Score] = scorePersitences.map { $0.toDomain() }

        return scores
    }

    func fetch(id: UUID) throws -> Score? {
        guard let scorePersistence: ScoreSchema.Score = try fetchPersistence(id: id) else {
            return nil
        }

        let score: Score = scorePersistence.toDomain()

        return score
    }

    func insert(_ score: Score) throws {
        let scorePersistence: ScoreSchema.Score = score.toPersistence()

        context.insert(scorePersistence)

        try context.save()
    }

    func update(_ score: Score) throws {
        let id: UUID = score.id
        guard let scorePersistence: ScoreSchema.Score = try fetchPersistence(id: id) else {
            return
        }

        scorePersistence.apply(domain: score)

        try context.save()
    }

    func delete(_ score: Score) throws {
        if score.isDeleted == true {
            /// Soft Delete 상태면 Hard Delete 수행
            let id: UUID = score.id
            guard let scorePersistence: ScoreSchema.Score = try fetchPersistence(id: id) else {
                return
            }

            try? FileManager.default.removeItem(at: score.audioURL)

            context.delete(scorePersistence)

            try context.save()
        } else {
            /// Soft Delete 수행
            score.setDeleted(true)

            try update(score)
        }
    }

    private func fetchPersistence(id: UUID) throws -> ScoreSchema.Score? {
        let predicate: Predicate<ScoreSchema.Score> = #Predicate { $0.id == id }
        let fetchDescriptor: FetchDescriptor<ScoreSchema.Score> = .init(predicate: predicate)
        let scorePersistence: ScoreSchema.Score? = try context.fetch(fetchDescriptor).first

        return scorePersistence
    }
}

extension Score {
    fileprivate func toPersistence() -> ScoreSchema.Score {
        return .init(
            id: self.id,
            title: self.title,
            key: self.key.toPersistence(),
            audioFileName: self.audioURL.lastPathComponent,
            totalDuration: self.totalDuration,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt,
            notes: self.notes.map { $0.toPersistence() },
            chordCells: self.chordCells.map { $0.toPersistence() },
            audioLevels: self.audioLevels,
            isDeleted: self.isDeleted
        )
    }
}

extension ScoreSchema.Score {
    fileprivate func toDomain() -> Score {
        return .init(
            id: self.id,
            title: self.title,
            key: self.key.toDomain(),
            audioURL: Score.recordingFolder.appending(component: audioFileName),
            totalDuration: self.totalDuration,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt,
            notes: self.notes.map { $0.toDomain() },
            chordCells: self.chordCells.map { $0.toDomain() },
            audioLevels: self.audioLevels,
            isDeleted: self.isDeleted
        )
    }
}

extension ScoreSchema.Score {
    fileprivate func apply(domain: Score) {
        self.title = domain.title
        self.key = domain.key.toPersistence()
        self.audioFileName = domain.audioURL.lastPathComponent
        self.totalDuration = domain.totalDuration
        self.createdAt = domain.createdAt
        self.updatedAt = domain.updatedAt
        self.notes = domain.notes.map { $0.toPersistence() }
        self.chordCells = domain.chordCells.map { $0.toPersistence() }
        self.audioLevels = domain.audioLevels
        self.isDeleted = domain.isDeleted
    }
}

extension NoteName {
    fileprivate func toPersistence() -> ScoreSchema.NoteName {
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

extension ScoreSchema.NoteName {
    fileprivate func toDomain() -> NoteName {
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

extension Key {
    fileprivate func toPersistence() -> ScoreSchema.Key {
        return .init(root: self.root.toPersistence())
    }
}

extension ScoreSchema.Key {
    fileprivate func toDomain() -> Key {
        return .init(root: self.root.toDomain())
    }
}

extension Note {
    fileprivate func toPersistence() -> ScoreSchema.Note {
        return .init(
            name: self.name.toPersistence(), octave: self.octave, startTime: self.startTime,
            duration: self.duration)
    }
}

extension ScoreSchema.Note {
    fileprivate func toDomain() -> Note {
        return .init(
            name: self.name.toDomain(), octave: self.octave, startTime: self.startTime,
            duration: self.duration)
    }
}

extension ChordQuality {
    fileprivate func toPersistence() -> ScoreSchema.ChordQuality {
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

extension ScoreSchema.ChordQuality {
    fileprivate func toDomain() -> ChordQuality {
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

extension Chord {
    fileprivate func toPersistence() -> ScoreSchema.Chord {
        return .init(root: self.root.toPersistence(), quality: self.quality.toPersistence())
    }
}

extension ScoreSchema.Chord {
    fileprivate func toDomain() -> Chord {
        return .init(root: self.root.toDomain(), quality: self.quality.toDomain())
    }
}

extension ChordCell {
    fileprivate func toPersistence() -> ScoreSchema.ChordCell {
        return .init(
            chord: self.chord?.toPersistence(),
            chordCandidates: self.chordCandidates.map { $0.toPersistence() },
            startTime: self.startTime)
    }
}

extension ScoreSchema.ChordCell {
    fileprivate func toDomain() -> ChordCell {
        return .init(
            chord: self.chord?.toDomain(),
            chordCandidates: self.chordCandidates.map { $0.toDomain() }, startTime: self.startTime)
    }
}
