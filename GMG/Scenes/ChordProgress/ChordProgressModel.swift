//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

protocol ChordProgressModelStateProtocol {
    var score: Score { get }
    var isEditMode: Bool { get }
    var playhead: Playhead { get }
    var currentChordCell: ChordCell? { get }
    var selectedChordCell: ChordCell? { get }
    var canUndo: Bool { get }
    var canRedo: Bool { get }
}

protocol ChordProgressModelActionProtocol: AnyObject {
    func setEditMode(_ isEditMode: Bool)
    func updatePlayhead(_ playhead: Playhead)
    func selectChordCell(_ chordCell: ChordCell?)
    func replaceChord(with candidate: Chord, for cell: ChordCell)
    func undoLastChange()
    func redoLastChange()
}

@Observable
final class ChordProgressModel:
    ChordProgressModelStateProtocol,
    ChordProgressModelActionProtocol
{
    private struct ChordEditHistoryEntry {
        let cellIndex: Int
        let previousChord: Chord?
        let newChord: Chord?
    }

    private(set) var score: Score
    private(set) var isEditMode: Bool
    private(set) var playhead: Playhead
    private(set) var currentChordCell: ChordCell?
    private(set) var selectedChordCell: ChordCell?
    private var undoStack: [ChordEditHistoryEntry]
    private var redoStack: [ChordEditHistoryEntry]

    init(score: Score) {
        self.score = score
        self.isEditMode = false
        self.playhead = Playhead(isPlaying: false, elapsedTime: .zero)
        self.currentChordCell = nil
        self.selectedChordCell = nil
        self.undoStack = []
        self.redoStack = []
    }
    
    var canUndo: Bool {
        !undoStack.isEmpty
    }
    
    var canRedo: Bool {
        !redoStack.isEmpty
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
        
        let entry = ChordEditHistoryEntry(
            cellIndex: cellIndex,
            previousChord: previousChord,
            newChord: selectedCandidate
        )
        undoStack.append(entry)
        redoStack.removeAll()

        score.updateChordCellBy(cellIndex: cellIndex, chord: selectedCandidate)
        updateSelectedCell(at: cellIndex)
    }
    
    func undoLastChange() {
        guard let lastEntry = undoStack.popLast() else { return }
        
        applyHistoryEntry(lastEntry, chord: lastEntry.previousChord)
        redoStack.append(lastEntry)
    }
    
    func redoLastChange() {
        guard let entry = redoStack.popLast() else { return }
        
        applyHistoryEntry(entry, chord: entry.newChord)
        undoStack.append(entry)
    }
    
    private func applyHistoryEntry(
        _ entry: ChordEditHistoryEntry,
        chord: Chord?
    ) {
        score.updateChordCellBy(cellIndex: entry.cellIndex, chord: chord)
        updateSelectedCell(at: entry.cellIndex)
    }
    
    private func updateSelectedCell(at index: Int) {
        guard let updatedCell = score.retrieveChordCellBy(cellIndex: index) else {
            return
        }
        
        selectedChordCell = updatedCell
    }
}
