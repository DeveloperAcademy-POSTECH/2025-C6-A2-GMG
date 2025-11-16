//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import UIKit

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
    func replaceChord(with candidate: Chord, for cell: ChordCell)
    func updateTitle(_ title: String)
    func setUndoManager(_ undoManager: UndoManager?)
    func performUndo()
    func performRedo()
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
    private(set) var undoManager: UndoManager?

    init(score: Score) {
        self.score = score
        self.isEditMode = false
        self.playhead = Playhead(isPlaying: false, elapsedTime: .zero)
        self.isMuted = false
        self.currentChordCell = nil
        self.selectedChordCell = nil
        self.undoManager = nil
    }

    var canUndo: Bool {
        undoManager?.canUndo ?? false
    }

    var canRedo: Bool {
        undoManager?.canRedo ?? false
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

    func replaceChord(with selectedCandidate: Chord, for cell: ChordCell) {
        guard let cellIndex: Int = score.retrieveCellIndexBy(time: cell.startTime),
            let originalCell: ChordCell = score.retrieveChordCellBy(cellIndex: cellIndex)
        else {
            return
        }

        let previousChord: Chord? = originalCell.chord
        if previousChord == selectedCandidate {
            return
        }

        registerUndoRedoHandlers(
            cellIndex: cellIndex,
            previousChord: previousChord,
            newChord: selectedCandidate
        )

        score.updateChordCellBy(cellIndex: cellIndex, chord: selectedCandidate)
        updateSelectedCell(at: cellIndex)
    }
    
    func updateTitle(_ title: String) {
        score.updateTitle(title)
    }
    
    func setUndoManager(_ undoManager: UndoManager?) {
        self.undoManager = undoManager
    }

    func performUndo() {
        undoManager?.undo()
    }

    func performRedo() {
        undoManager?.redo()
    }

    private func updateSelectedCell(at index: Int) {
        guard let updatedCell = score.retrieveChordCellBy(cellIndex: index) else {
            return
        }

        selectedChordCell = updatedCell
    }

    private func registerUndoRedoHandlers(
        cellIndex: Int,
        previousChord: Chord?,
        newChord: Chord?
    ) {
        guard let undoManager else { return }

        undoManager.registerUndo(withTarget: self) { target in
            target.score.updateChordCellBy(cellIndex: cellIndex, chord: previousChord)
            target.updateSelectedCell(at: cellIndex)
            target.registerUndoRedoHandlers(
                cellIndex: cellIndex,
                previousChord: newChord,
                newChord: previousChord
            )
        }
        undoManager.setActionName("Chord Change")
    }
}
