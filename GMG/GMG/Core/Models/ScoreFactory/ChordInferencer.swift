//  Copyright © 2025 ADA 4th GMG. All rights reserved.

struct ChordInferencerResult {
    let key: Key
    let chordCells: [ChordCell]
}

final class ChordInferencer {
    func inference(notes: [Note]) -> ChordInferencerResult {
        ChordInferencerResult(key: Key(root: .C), chordCells: [])
    }
}
