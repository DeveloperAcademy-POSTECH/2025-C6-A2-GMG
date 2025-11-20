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
    func onDragWaveformStart(_ time: TimeInterval)
    func onDragWaveformChange(_ time: TimeInterval)
    func onDragWaveformEnd(_ time: TimeInterval)
    func onTapCandidateChordCell(
        _ candidate: Chord,
        in chordCell: ChordCell,
        for score: Score
    )
    func onTapUndoButton()
    func onTapRedoButton()
    func onEnterTitle(_ title: String, for score: Score)
}

final class ChordProgressIntent: ChordProgressIntentProtocol {
    private weak var model: ChordProgressModelActionProtocol?

    private let scoreRepository: ScoreRepository

    private var scorePlayer: ScorePlayer?

    private var cancellables: Set<AnyCancellable>

    private let undoManager: UndoManager

    init(
        model: ChordProgressModelActionProtocol,
        scoreRepository: ScoreRepository
    ) {
        self.model = model

        self.scoreRepository = scoreRepository

        self.scorePlayer = nil

        self.cancellables = Set<AnyCancellable>()

        self.undoManager = UndoManager()
    }

    func onAppear(_ score: Score) {
        do {
            let scorePlayer = ScorePlayer(score: score)

            try scorePlayer.prepareToPlay()

            self.scorePlayer = scorePlayer

            setupScorePlayerPublisher()

            setupUndoManagerPublisher()
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

        scorePlayer.seek(to: time)
    }

    func onDragWaveformStart(_ time: TimeInterval) {
        guard let scorePlayer = self.scorePlayer else { return }
        scorePlayer.pause()
        scorePlayer.seek(to: time)
    }

    func onDragWaveformChange(_ time: TimeInterval) {
        guard let scorePlayer = self.scorePlayer else { return }
        scorePlayer.seek(to: time)
    }

    func onDragWaveformEnd(_ time: TimeInterval) {
        guard let scorePlayer = self.scorePlayer else { return }
        scorePlayer.seek(to: time)

        if scorePlayer.previousIsPlaying {
            scorePlayer.play()
        }
    }

    func onTapCandidateChordCell(
        _ candidate: Chord,
        in chordCell: ChordCell,
        for score: Score
    ) {
        guard let scorePlayer = self.scorePlayer,
            chordCell.chordCandidates.contains(where: { $0 == candidate })
        else { return }

        scorePlayer.play(chord: candidate)

        let previousChord: Chord? = chordCell.chord
        guard previousChord != candidate else { return }

        replaceChord(
            oldChord: previousChord,
            newChord: candidate,
            chordCell: chordCell,
            score: score
        )
    }

    func onTapUndoButton() {
        undoManager.undo()
    }

    func onTapRedoButton() {
        undoManager.redo()
    }

    func onEnterTitle(
        _ title: String,
        for score: Score
    ) {
        updateScoreTitle(oldTitle: score.title, newTitle: title, score: score)
    }

    private func setupScorePlayerPublisher() {
        guard let scorePlayer = self.scorePlayer else { return }

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
    }

    private func setupUndoManagerPublisher() {
        let notificationCenter: NotificationCenter = .default
        let notificationNames: [Notification.Name] = [
            .NSUndoManagerDidOpenUndoGroup,
            .NSUndoManagerDidCloseUndoGroup,
            .NSUndoManagerDidUndoChange,
            .NSUndoManagerDidRedoChange,
        ]
        let undoManagerPublishers: [NotificationCenter.Publisher] = notificationNames.map {
            notificationName in
            return notificationCenter.publisher(for: notificationName)
        }

        let undoManagerMergedPublisher: Publishers.MergeMany<NotificationCenter.Publisher> =
            Publishers.MergeMany(undoManagerPublishers)

        undoManagerMergedPublisher
            .sink { [weak self] _ in
                guard let self else { return }
                self.updateCanUndoRedo()
            }
            .store(in: &cancellables)
    }

    private func updateCanUndoRedo() {
        guard let model = self.model else { return }

        let canUndo: Bool = undoManager.canUndo
        let canRedo: Bool = undoManager.canRedo

        model.updateCanUndo(canUndo)
        model.updateCanRedo(canRedo)
    }

    private func replaceChord(
        oldChord: Chord?,
        newChord: Chord?,
        chordCell: ChordCell,
        score: Score
    ) {
        guard let model = self.model, let scorePlayer = self.scorePlayer else { return }

        undoManager.registerUndo(withTarget: self) { target in
            target.replaceChord(
                oldChord: newChord,
                newChord: oldChord,
                chordCell: chordCell,
                score: score
            )
        }
        undoManager.setActionName("Update Chord")

        model.replaceChord(with: newChord, for: chordCell)
        scorePlayer.prepareChordCells()

        updateScore(score)
    }

    private func updateScoreTitle(
        oldTitle: String,
        newTitle: String,
        score: Score
    ) {
        guard let model = self.model else { return }

        undoManager.registerUndo(withTarget: self) { target in
            target.updateScoreTitle(oldTitle: newTitle, newTitle: oldTitle, score: score)
        }
        undoManager.setActionName("Update Title")

        model.updateTitle(newTitle)

        updateScore(score)
    }

    private func updateScore(_ score: Score) {
        do {
            try scoreRepository.update(score)
        } catch {
            Logger.error(String(describing: error))
        }
    }
}
