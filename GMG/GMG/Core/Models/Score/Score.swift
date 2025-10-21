//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

class Score {
    let bpm: BPM
    let timeSignature: TimeSignature
    let key: Key
    let humFileURL: URL
    private let measures: [Measure]

    init(
        bpm: BPM,
        timeSignature: TimeSignature,
        key: Key,
        humFileURL: URL,
        measures: [Measure]
    ) {
        self.bpm = bpm
        self.timeSignature = timeSignature
        self.key = key
        self.humFileURL = humFileURL
        self.measures = measures
    }

    func retrieveMeasureBy(measureIndex: Int) -> Measure {
        Measure(notes: [], chordCells: [])
    }
    
    func retrieveChordCellsBy(measureIndex: Int) -> [ChordCell] {
        []
    }
    
    func retrieveMeasureIndexBy(time: TimeInterval) -> Int {
        0
    }
    
    func retrieveCellIndexBy(time: TimeInterval) -> Int {
        0
    }
    
    func retrieveChordBy(time: TimeInterval) -> Chord {
        Chord(root: .C, quality: .maj)
    }
    
    func retrieveChordCellBy(measureIndex: Int, chordIndex: Int) -> ChordCell {
        ChordCell(chord: nil, chordCandidates: [])
    }
    
    func updateChordCellBy(measureIndex: Int, chordIndex: Int, chord: Chord) {
        
    }
}
