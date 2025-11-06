//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftData

@Model
class Score {
    var id: UUID = UUID()
    var title: String
    var key: Key
    var audioUrl: URL
    var totalDuration: TimeInterval
    var createdAt: Date
    var updatedAt: Date
    var notes: [Note]
    var chordCells: [ChordCell]

    init(
        title: String,
        key: Key,
        audioUrl: URL,
        totalDuration: TimeInterval,
        createdAt: Date,
        updatedAt: Date,
        notes: [Note],
        chordCells: [ChordCell]  // 정렬되어 있어야 함
    ) {
        self.title = title
        self.key = key
        self.audioUrl = audioUrl
        self.totalDuration = totalDuration
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notes = notes
        self.chordCells = chordCells
    }

    func retrieveAllChordCells() -> [ChordCell] {
        return self.chordCells
    }

    func retrieveCellIndexBy(time: TimeInterval) -> Int? {
        let index: Int? = chordCells.lastIndex { chordCell in
            chordCell.startTime <= time
        }

        return index
    }

    func retrieveChordBy(time: TimeInterval) -> Chord? {
        guard let index: Int = retrieveCellIndexBy(time: time) else {
            return nil
        }

        guard let chordCell: ChordCell = retrieveChordCellBy(cellIndex: index)
        else {
            return nil
        }

        let chord: Chord? = chordCell.chord

        return chord
    }

    func retrieveChordCellBy(cellIndex: Int) -> ChordCell? {
        guard chordCells.indices.contains(cellIndex) else { return nil }

        return chordCells[cellIndex]
    }

    func updateChordCellBy(cellIndex: Int, chord: Chord) {
        guard chordCells.indices.contains(cellIndex) else { return }

        let chordCell: ChordCell = chordCells[cellIndex]
        let newChordCell: ChordCell = ChordCell(
            chord: chord,
            chordCandidates: chordCell.chordCandidates,
            startTime: chordCell.startTime
        )

        chordCells[cellIndex] = newChordCell
    }
}

extension Score {
    static var mock: Score {
        Score(
            title: "Untitled",
            key: Key(root: .C),
            audioUrl: Bundle.main.bundleURL,
            totalDuration: 31.0,
            createdAt: Date(),
            updatedAt: Date(),
            notes: [],
            chordCells: [
                ChordCell(
                    chord: Chord(root: .C, quality: .maj),
                    chordCandidates: [],
                    startTime: 0.0
                ),
                ChordCell(
                    chord: Chord(root: .D, quality: .min),
                    chordCandidates: [],
                    startTime: 2.5
                ),
                ChordCell(
                    chord: Chord(root: .E, quality: .dim),
                    chordCandidates: [],
                    startTime: 5.0
                ),
                ChordCell(
                    chord: Chord(root: .F, quality: .maj9),
                    chordCandidates: [],
                    startTime: 10.0
                ),
                ChordCell(
                    chord: Chord(root: .Bb, quality: .halfDim7),
                    chordCandidates: [],
                    startTime: 13.0
                ),
            ]
        )
    }
}
