//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

protocol ChordProgressModelStateProtocol {
    var score: Score { get }
    var isEditMode: Bool { get }
    var playhead: Playhead { get }
    var currentChordCell: ChordCell? { get }
    var selectedChordCell: ChordCell? { get }
}

protocol ChordProgressModelActionProtocol: AnyObject {
    func setEditMode(_ isEditMode: Bool)
    func updatePlayhead(_ playhead: Playhead)
    func selectChordCell(_ chordCell: ChordCell?)
}

@Observable
final class ChordProgressModel:
    ChordProgressModelStateProtocol,
    ChordProgressModelActionProtocol
{
    private(set) var score: Score
    private(set) var isEditMode: Bool
    private(set) var playhead: Playhead
    private(set) var currentChordCell: ChordCell?
    private(set) var selectedChordCell: ChordCell?

    init(score: Score) {
        self.score = score
        self.isEditMode = false
        self.playhead = Playhead(isPlaying: false, elapsedTime: .zero)
        self.currentChordCell = nil
        self.selectedChordCell = nil
    }

    func setEditMode(_ isEditMode: Bool) {
        self.isEditMode = isEditMode
    }

    func updatePlayhead(_ playhead: Playhead) {
        if self.playhead != playhead {
            self.playhead = playhead

            if let currentChordCellIndex: Int =
                score.retrieveCellIndexBy(time: playhead.elapsedTime + 0.01),
                let currentChordCell: ChordCell =
                    score.retrieveChordCellBy(cellIndex: currentChordCellIndex)
            {
                self.currentChordCell = currentChordCell
            }
        }
    }

    func selectChordCell(_ chordCell: ChordCell?) {
        self.selectedChordCell = chordCell
    }
}
