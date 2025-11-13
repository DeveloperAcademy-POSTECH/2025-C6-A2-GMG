//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Combine
import Foundation
import SwiftData

protocol HomeIntentProtocol {
    func loadScores(_ context: ModelContext)
    func setIsLatest(_ isLatest: Bool)
    func deleteScore(_ score: Score, context: ModelContext)
    func selectScore(_ score: Score?)
    func renameScore(_ score: Score, newTitle: String)
    func onAppear(_ score: Score)
    func onTapPlayButton()
    func onTapStopButton()
    func openScore(_ score: Score, context: ModelContext)
}

final class HomeIntent: HomeIntentProtocol {
    private var model: HomeModelActionProtocol?
    private var scorePlayer: ScorePlayer?
    private var cancellables: Set<AnyCancellable>

    init(model: HomeModelActionProtocol) {
        self.model = model
        self.scorePlayer = nil
        self.cancellables = []
    }

    func loadScores(_ context: ModelContext) {
        model?.fetchScores(context)
    }

    func setIsLatest(_ isLatest: Bool) {
        model?.setIsLatest(isLatest)
    }

    func deleteScore(_ score: Score, context: ModelContext) {
        model?.deleteScore(score, context: context)
    }

    func selectScore(_ score: Score?) {
        model?.setSelectedScore(score)
    }

    func renameScore(_ score: Score, newTitle: String) {
        model?.renameScore(score, newTitle: newTitle)
    }

    func onAppear(_ score: Score) {
        // Clean up previous player and subscriptions
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

    func onTapPlayButton() {
        model?.startPlaying()
        scorePlayer?.play()
    }

    func onTapStopButton() {
        model?.stopPlaying()
        scorePlayer?.stop()
    }

    func openScore(_ score: Score, context: ModelContext) {
        // 1. updatedAt 갱신
        model?.setUpdatedAt(score, at: .now)

        // 2. 선택 상태로 만들어 주고
        model?.setSelectedScore(score)

        // 3. 정렬 바뀐 걸 반영하고 싶으면 필요 시 다시 fetch
        model?.fetchScores(context)
    }
}
