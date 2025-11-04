//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

struct ChordCell: Codable {
    let chord: Chord?
    let chordCandidates: [Chord]
    let startTime: TimeInterval
}
