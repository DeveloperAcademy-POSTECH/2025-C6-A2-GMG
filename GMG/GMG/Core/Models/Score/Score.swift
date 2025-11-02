//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

class Score {
    let title: String
    let key: Key
    let audioUrl: URL
    let totalDuration: TimeInterval
    private let notes: [Note]
    private let chordCells: [ChordCell]

    init(
        title: String,
        key: Key,
        audioUrl: URL,
        totalDuration: TimeInterval,
        notes: [Note],
        chordCells: [ChordCell]
    ) {
        self.title = title
        self.key = key
        self.audioUrl = audioUrl
        self.totalDuration = totalDuration
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
