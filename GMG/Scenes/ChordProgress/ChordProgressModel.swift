//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
internal import UIKit

protocol ChordProgressModelStateProtocol {
    var score: Score { get }
    var isEditMode: Bool { get }
    var playhead: Playhead { get }
    var isMuted: Bool { get }
    var currentChordCell: ChordCell? { get }
    var selectedChordCell: ChordCell? { get }
    var canUndo: Bool { get }
    var canRedo: Bool { get }
}

protocol ChordProgressModelActionProtocol: AnyObject {
    func setEditMode(_ isEditMode: Bool)
    func updatePlayhead(_ playhead: Playhead)
    func setMuted(_ isMuted: Bool)
    func selectChordCell(_ chordCell: ChordCell?)
    func replaceChord(with candidate: Chord?, for cell: ChordCell)
    func updateTitle(_ title: String)
    func updateCanUndo(_ canUndo: Bool)
    func updateCanRedo(_ canRedo: Bool)
}

@Observable
final class ChordProgressModel:
    ChordProgressModelStateProtocol,
    ChordProgressModelActionProtocol
{
    private(set) var score: Score
    private(set) var isEditMode: Bool
    private(set) var playhead: Playhead
    private(set) var isMuted: Bool
    private(set) var currentChordCell: ChordCell?
    private(set) var selectedChordCell: ChordCell?
    private(set) var canUndo: Bool
    private(set) var canRedo: Bool

    init(score: Score) {
        self.score = score
        self.isEditMode = false
        self.playhead = Playhead(isPlaying: false, elapsedTime: .zero)
        self.isMuted = false
        self.currentChordCell = nil
        self.selectedChordCell = nil
        self.canUndo = false
        self.canRedo = false
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

    func setMuted(_ isMuted: Bool) {
        self.isMuted = isMuted
    }

    func selectChordCell(_ chordCell: ChordCell?) {
        self.selectedChordCell = chordCell
    }

    func replaceChord(with selectedCandidate: Chord?, for cell: ChordCell) {
        guard let cellIndex: Int = score.retrieveCellIndexBy(time: cell.startTime),
            let originalCell: ChordCell = score.retrieveChordCellBy(cellIndex: cellIndex)
        else {
            return
        }

        let previousChord: Chord? = originalCell.chord
        if previousChord == selectedCandidate {
            return
        }

        score.updateChordCellBy(cellIndex: cellIndex, chord: selectedCandidate)
        updateSelectedCell(at: cellIndex)
    }

    func updateTitle(_ title: String) {
        score.updateTitle(title)
    }

    func updateCanUndo(_ canUndo: Bool) {
        self.canUndo = canUndo
    }

    func updateCanRedo(_ canRedo: Bool) {
        self.canRedo = canRedo
    }

    private func updateSelectedCell(at index: Int) {
        guard let updatedCell = score.retrieveChordCellBy(cellIndex: index) else {
            return
        }

        selectedChordCell = updatedCell
    }
}
