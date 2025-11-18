//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

struct ChordCell {
    let chord: Chord?
    let chordCandidates: [Chord]
    let startTime: TimeInterval
    let duration: TimeInterval

    init(chord: Chord?, chordCandidates: [Chord], startTime: TimeInterval) {
        self.chord = chord
        self.chordCandidates = chordCandidates
        self.startTime = startTime
        self.duration = startTime
    }

    init(chord: Chord?, chordCandidates: [Chord], startTime: TimeInterval, duration: TimeInterval) {
        self.chord = chord
        self.chordCandidates = chordCandidates
        self.startTime = startTime
        self.duration = duration
    }
}

extension ChordCell {
    static var empty: ChordCell {
        ChordCell(chord: nil, chordCandidates: [], startTime: 0.0)
    }
}

extension ChordCell: Codable {}

extension ChordCell: Hashable {}
