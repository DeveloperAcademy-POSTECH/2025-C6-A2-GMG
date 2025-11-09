//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Combine
import Foundation

protocol ChordProgressIntentProtocol {
    func onAppear(_ score: Score)
    func onDisappear()
    func onTapEditModeToggle(_ isEditMode: Bool)
    func onTapPlayButton()
    func onTapPauseButton()
    func onTapStopButton()
    func onTapChordCell(_ chordCell: ChordCell)
    func onTapCandidateChordCell(
        _ candidate: Chord,
        for chordCell: ChordCell
    )
    func onTapUndoButton()
    func onTapRedoButton()
}

final class ChordProgressIntent: ChordProgressIntentProtocol {
    private weak var model: ChordProgressModelActionProtocol?

    private var scorePlayer: ScorePlayer?

    private var cancellables: Set<AnyCancellable>

    private var creatingScoreTask: Task<Void, Never>?

    init(model: ChordProgressModelActionProtocol) {
        self.model = model

        self.scorePlayer = nil

        self.cancellables = Set<AnyCancellable>()
    }

    func onAppear(_ score: Score) {
        do {
            let scorePlayer = ScorePlayer(score: score)

            try scorePlayer.prepareToPlay()

            self.scorePlayer = scorePlayer

            scorePlayer.playheadPublisher
                .sink { [weak self] playhead in
                    self?.model?.updatePlayhead(playhead)
                }
                .store(in: &cancellables)
        } catch {
            Logger.error(String(describing: error))
        }
    }

    func onDisappear() {
        cancellables.removeAll()

        self.scorePlayer?.cleanupAfterPlay()

        self.scorePlayer = nil
    }

    func onTapEditModeToggle(_ isEditMode: Bool) {
        self.model?.setEditMode(isEditMode)
    }

    func onTapPlayButton() {
        self.scorePlayer?.play()
    }

    func onTapPauseButton() {
        self.scorePlayer?.pause()
    }

    func onTapStopButton() {
        self.scorePlayer?.stop()
    }

    func onTapChordCell(_ chordCell: ChordCell) {
        self.scorePlayer?.seek(chordCell: chordCell)
        self.model?.selectChordCell(chordCell)
    }
    
    func onTapCandidateChordCell(
        _ candidate: Chord,
        for chordCell: ChordCell
    ) {
        guard let scorePlayer = self.scorePlayer,
            let model = self.model,
            chordCell.chordCandidates.contains(where: { $0 == candidate })
        else { return }

        scorePlayer.play(chord: candidate)

        if chordCell.chord == candidate {
            return
        }

        model.replaceChord(with: candidate, for: chordCell)
    }
    
    func onTapUndoButton() {
        self.model?.undoLastChange()
    }
    
    func onTapRedoButton() {
        self.model?.redoLastChange()
    }
}
