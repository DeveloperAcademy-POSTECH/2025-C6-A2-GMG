//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Combine
import Foundation
import SwiftData

protocol HomeIntentProtocol {
    func onAppear()
    func onDisappear()
    func setLatest(_ isLatest: Bool)
    func selectScore(_ score: Score)
    func renameScore(_ score: Score, title: String)
    func requestDeleteScoreConfirmation(_ score: Score?)
    func deleteScore(_ score: Score)
    func onTapScore(_ score: Score)
    func onTapPlayButton(_ score: Score)
    func onTapStopButton()
}

final class HomeIntent: HomeIntentProtocol {
    private weak var model: HomeModelActionProtocol?

    private let scoreRepository: ScoreRepository
    private var scorePlayer: ScorePlayer?
    private var cancellables: Set<AnyCancellable>

    init(
        model: HomeModelActionProtocol,
        scoreRepository: ScoreRepository
    ) {
        self.model = model

        self.scoreRepository = scoreRepository
        self.scorePlayer = nil
        self.cancellables = []
    }

    func onAppear() {
        fetchScores()
    }

    func onDisappear() {
        cleanupPlayer()
    }

    func setLatest(_ isLatest: Bool) {
        guard let model else { return }

        model.setLatest(isLatest)
    }

    func selectScore(_ score: Score) {
        cleanupPlayer()

        guard let model else { return }

        model.selectScore(score)
    }

    func renameScore(_ score: Score, title: String) {
        do {
            guard let model else { return }

            model.updateTitle(score, title: title)

            try scoreRepository.update(score)
        } catch {
            Logger.error(String(describing: error))
        }
    }

    func requestDeleteScoreConfirmation(_ score: Score?) {
        guard let model = self.model else { return }

        model.setScoreToDelete(score)
    }

    func deleteScore(_ score: Score) {
        do {
            try scoreRepository.delete(score)

            fetchScores()
        } catch {
            Logger.error(String(describing: error))
        }
    }

    func onTapScore(_ score: Score) {
        do {
            guard let model else { return }

            model.setUpdatedAt(score, updatedAt: .now)

            try scoreRepository.update(score)

            model.selectScore(score)
        } catch {
            Logger.error(String(describing: error))
        }
    }

    func onTapPlayButton(_ score: Score) {
        guard let model else { return }
        model.selectScore(score)

        setupPlayer(for: score)

        guard let scorePlayer else { return }
        scorePlayer.play()
    }

    func onTapStopButton() {
        cleanupPlayer()
    }

    private func fetchScores() {
        guard let model else { return }

        do {
            let scores: [Score] = try scoreRepository.fetch()

            model.setScores(scores)
        } catch {
            Logger.error(String(describing: error))
        }
    }

    private func setupPlayer(for score: Score) {
        cleanupPlayer()

        do {
            let scorePlayer: ScorePlayer = DefaultScorePlayer(score: score)

            try scorePlayer.prepareToPlay()

            scorePlayer.playheadPublisher
                .sink { [weak self] playhead in
                    self?.model?.updatePlayhead(playhead)
                }
                .store(in: &cancellables)

            self.scorePlayer = scorePlayer
        } catch {
            Logger.error(String(describing: error))
        }
    }

    private func cleanupPlayer() {
        cancellables.removeAll()
        scorePlayer?.cleanupAfterPlay()
        scorePlayer = nil

        model?.updatePlayhead(
            Playhead(
                isPlaying: false,
                elapsedTime: .zero
            )
        )
    }
}
