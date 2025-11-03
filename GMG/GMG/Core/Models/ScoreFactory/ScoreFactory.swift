//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

class ScoreFactory {
    private let chordInferencer: ChordInferencer

    init() {
        self.chordInferencer = ChordInferencer()
    }

    func createScore(
        audioUrl: URL
    ) -> Score {
        Score(
            title: "",
            key: Key(root: .C),
            audioUrl: URL(filePath: ""),
            totalDuration: 0.0,
            createdAt: Date(),
            updatedAt: Date(),
            notes: [],
            chordCells: []
        )
    }

    private func convertAudioToNotes(audioUrl: URL) -> [Note] {
        []
    }
}
