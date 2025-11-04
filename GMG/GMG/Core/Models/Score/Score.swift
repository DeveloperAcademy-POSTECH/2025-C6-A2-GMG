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
        chordCells: [ChordCell]
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

    func retrieveCellIndexBy(time: TimeInterval) -> Int {
        0
    }

    func retrieveChordBy(time: TimeInterval) -> Chord {
        Chord(root: .C, quality: .maj)
    }

    func retrieveChordCellBy(cellIndex: Int) -> ChordCell {
        ChordCell(chord: nil, chordCandidates: [], startTime: 0.0)
    }

    func updateChordCellBy(cellIndex: Int, chord: Chord) {

    }
}
