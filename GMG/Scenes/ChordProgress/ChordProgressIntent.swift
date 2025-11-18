//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Combine
import Foundation
internal import UIKit

protocol ChordProgressIntentProtocol {
    func onAppear(_ score: Score)
    func onDisappear()
    func onTapEditModeToggle(_ isEditMode: Bool)
    func onTapPlayButton()
    func onTapPauseButton()
    func onTapStopButton()
    func onTapMuteButton(_ isMuted: Bool)
    func onTapChordCell(_ chordCell: ChordCell)
    func onTapWaveform(_ time: TimeInterval)
    func onTapCandidateChordCell(
        _ candidate: Chord,
        for chordCell: ChordCell
    )
    func onTapUndoButton()
    func onTapRedoButton()
    func onEnterTitle(_ title: String)
}

final class ChordProgressIntent: ChordProgressIntentProtocol {
    private weak var model: ChordProgressModelActionProtocol?

    private let scoreRepository: ScoreRepository

    private var scorePlayer: ScorePlayer?

    private var cancellables: Set<AnyCancellable>

    private let undoManager: UndoManager

    private var undoManagerObservers: [NSObjectProtocol]

    init(
        model: ChordProgressModelActionProtocol,
        scoreRepository: ScoreRepository
    ) {
        self.model = model

        self.scoreRepository = scoreRepository

        self.scorePlayer = nil

        self.cancellables = Set<AnyCancellable>()

        self.undoManager = UndoManager()

        self.undoManagerObservers = []
    }

    func onAppear(_ score: Score) {
        do {
            let scorePlayer = ScorePlayer(score: score)

            try scorePlayer.prepareToPlay()

            self.scorePlayer = scorePlayer

            scorePlayer.playerMutedPublisher
                .sink { [weak self] isPlayerMuted in
                    self?.model?.setMuted(isPlayerMuted)
                }
                .store(in: &cancellables)

            scorePlayer.playheadPublisher
                .sink { [weak self] playhead in
                    self?.model?.updatePlayhead(playhead)
                }
                .store(in: &cancellables)

            registerUndoManagerObservers()
        } catch {
            Logger.error(String(describing: error))
        }
    }

    func onDisappear() {
        cancellables.removeAll()

        unregisterUndoManagerObservers()

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

    func onTapMuteButton(_ isMuted: Bool) {
        self.scorePlayer?.setPlayerMuted(isMuted)
    }

    func onTapChordCell(_ chordCell: ChordCell) {
        guard let scorePlayer = self.scorePlayer else { return }
        guard let model = self.model else { return }

        scorePlayer.seek(chordCell: chordCell)
        model.selectChordCell(chordCell)
    }

    func onTapWaveform(_ time: TimeInterval) {
        guard let scorePlayer = self.scorePlayer else { return }

        scorePlayer.pause()
        scorePlayer.seek(to: time)
    }

    func onTapCandidateChordCell(
        _ candidate: Chord,
        for chordCell: ChordCell
    ) {
        guard let scorePlayer = self.scorePlayer,
            chordCell.chordCandidates.contains(where: { $0 == candidate })
        else { return }

        scorePlayer.play(chord: candidate)

        let previousChord: Chord? = chordCell.chord
        guard previousChord != candidate else { return }

        replaceChord(candidate, for: chordCell)

        registerReplaceChordUndoHandler(
            chordCell: chordCell,
            oldChord: previousChord,
            newChord: candidate
        )
    }

    func onTapUndoButton() {
        undoManager.undo()
    }

    func onTapRedoButton() {
        undoManager.redo()
    }

    func onEnterTitle(_ title: String) {
        guard let model = self.model else { return }

        model.updateTitle(title)
    }

    private func registerUndoManagerObservers() {
        let notificationCenter: NotificationCenter = .default
        let notificationNames: [Notification.Name] = [
            .NSUndoManagerDidOpenUndoGroup,
            .NSUndoManagerDidCloseUndoGroup,
            .NSUndoManagerDidUndoChange,
            .NSUndoManagerDidRedoChange,
        ]

        let observers: [NSObjectProtocol] =
            notificationNames
            .map { notificationName in
                return notificationCenter.addObserver(
                    forName: notificationName,
                    object: nil,
                    queue: nil
                ) { [weak self] notification in
                    self?.updateCanUndoRedo()
                }
            }

        self.undoManagerObservers = observers
    }

    private func unregisterUndoManagerObservers() {
        let notificationCenter: NotificationCenter = .default

        self.undoManagerObservers.forEach { observer in
            notificationCenter.removeObserver(observer)
        }

        self.undoManagerObservers.removeAll()
    }

    private func updateCanUndoRedo() {
        guard let model = self.model else { return }

        let canUndo: Bool = undoManager.canUndo
        let canRedo: Bool = undoManager.canRedo

        model.updateCanUndo(canUndo)
        model.updateCanRedo(canRedo)
    }

    private func replaceChord(_ chord: Chord?, for chordCell: ChordCell) {
        guard let model = self.model, let scorePlayer = self.scorePlayer else { return }

        model.replaceChord(with: chord, for: chordCell)
        scorePlayer.prepareChordCells()
    }

    private func registerReplaceChordUndoHandler(
        chordCell: ChordCell,
        oldChord: Chord?,
        newChord: Chord?
    ) {
        undoManager.registerUndo(withTarget: self) { target in
            target.replaceChord(oldChord, for: chordCell)
            target.registerReplaceChordUndoHandler(
                chordCell: chordCell,
                oldChord: newChord,
                newChord: oldChord
            )
        }
        undoManager.setActionName("Chord Change")
    }
}
