//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

struct ChordCell {
    let chord: Chord?
    let chordCandidates: [Chord]
    let startTime: TimeInterval
}

extension ChordCell {
    static var empty: ChordCell {
        ChordCell(chord: nil, chordCandidates: [], startTime: 0.0)
    }
}

extension ChordCell: Codable {}
extension ChordCell: Hashable {}
