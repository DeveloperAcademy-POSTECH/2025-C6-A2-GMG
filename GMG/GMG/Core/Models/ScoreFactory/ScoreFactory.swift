//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

class ScoreFactory {
    private let chordInferencer: ChordInferencer

    init() {
        self.chordInferencer = ChordInferencer()
    }

    func createScore(
        samples: [FeatureSample],
        bpm: BPM,
        timeSignature: TimeSignature
    ) -> Score {
        Score(
            bpm: BPM(value: 96),
            timeSignature: TimeSignature.fourFour,
            key: Key(root: .C, type: .major),
            humFileURL: .temporaryDirectory,
            measures: []
        )
    }

    private func convertMeasures(
        samples: [FeatureSample],
        bpm: BPM,
        timeSignature: TimeSignature
    ) -> [Measure] {
        []
    }

    private func findKey(measures: [Measure]) -> Key {
        Key(root: .C, type: .major)
    }
}
