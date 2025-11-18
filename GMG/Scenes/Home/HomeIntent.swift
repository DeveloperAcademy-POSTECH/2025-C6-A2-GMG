//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Combine
import Foundation
import SwiftData

protocol HomeIntentProtocol {
    func onAppear()
    func onDisappear()
    func setIsLatest(_ isLatest: Bool)
    func selectScore(_ score: Score)
    func renameScore(_ score: Score, newTitle: String)
    func requestDeleteScoreConfirmation(_ score: Score?)
    func deleteScore(_ score: Score)
    func onTapScore(_ score: Score)
    func onTapPlayButton(score: Score, selectedScore: Score?)
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

    func setIsLatest(_ isLatest: Bool) {
        guard let model else { return }

        model.setIsLatest(isLatest)
    }

    func selectScore(_ score: Score) {
        guard let model else { return }

        scorePlayer?.stop()

        model.setSelectedScore(score)
    }

    func renameScore(_ score: Score, newTitle: String) {
        do {
            score.updateTitle(newTitle)

            try scoreRepository.update(score)

            model?.updateScore(score)
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
        guard let model else { return }

        do {
            score.setUpdatedAt(.now)
            try scoreRepository.update(score)
            model.updateScore(score)
        } catch {
            Logger.error(String(describing: error))
        }

        model.setSelectedScore(score)
    }

    func onTapPlayButton(score: Score, selectedScore: Score?) {
        if selectedScore?.id != score.id {
            model?.setSelectedScore(score)
        }
        setupPlayer(for: score)
        scorePlayer?.play()
    }

    func onTapStopButton() {
        scorePlayer?.stop()
    }

    private func fetchScores() {
        guard let model else { return }

        do {
            let scores: [Score] = try scoreRepository.fetch()
            model.setAllScores(scores)
        } catch {
            Logger.error(String(describing: error))
        }
    }

    private func setupPlayer(for score: Score) {
        cleanupPlayer()

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

    private func cleanupPlayer() {
        cancellables.removeAll()
        scorePlayer?.cleanupAfterPlay()
        scorePlayer = nil
    }
}
