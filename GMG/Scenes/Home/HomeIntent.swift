//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Combine
import Foundation
import SwiftData

protocol HomeIntentProtocol {
    func onAppear()
    func setIsLatest(_ isLatest: Bool)
    func selectScore(_ score: Score)
    func renameScore(_ score: Score, newTitle: String)
    func deleteScore(_ score: Score)
    func onTapScore(_ score: Score)
    func onTapPlayButton(score: Score, selectedScore: Score?)
    func onTapStopButton()
    func selectLastScore(_ scores: [Score])
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
        } catch {
            Logger.error(String(describing: error))
        }
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

        score.setUpdatedAt(.now)

        do {
            try scoreRepository.update(score)
        } catch {
            Logger.error(String(describing: error))
        }

        model.setSelectedScore(score)
    }

    func onTapPlayButton(score: Score, selectedScore: Score?) {
        if selectedScore?.id != score.id {
            model?.setSelectedScore(score)
            setupPlayer(for: score)
        } else {
            setupPlayer(for: score)
        }

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

            let sortedForSelection = scores.sorted {
                ($0.updatedAt, $0.createdAt) > ($1.updatedAt, $1.createdAt)
            }

            selectLastScore(sortedForSelection)
        } catch {
            Logger.error(String(describing: error))
        }
    }

    private func setupPlayer(for score: Score) {
        cancellables.removeAll()
        scorePlayer?.cleanupAfterPlay()
        scorePlayer = nil

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

    func selectLastScore(_ scores: [Score]) {
        guard let model else { return }

        if scores.isEmpty {
            model.setSelectedScore(nil)
            return
        }

        let last = scores.last!
        model.setSelectedScore(last)
    }
}
