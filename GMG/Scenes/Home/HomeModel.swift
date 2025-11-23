//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftData

protocol HomeModelStateProtocol {
    var songCount: Int { get }
    var isLatest: Bool { get }
    var recentScores: [Score] { get }
    var sortedScores: [Score] { get }
    var selectedScore: Score? { get }
    var scoreToDelete: Score? { get }
    var playhead: Playhead { get }
}

protocol HomeModelActionProtocol: AnyObject {
    func setScores(_ scores: [Score])
    func setLatest(_ isLatest: Bool)
    func selectScore(_ score: Score?)
    func setScoreToDelete(_ score: Score?)
    func updatePlayhead(_ playhead: Playhead)

    func updateTitle(_ score: Score, title: String)
    func setUpdatedAt(_ score: Score, updatedAt: Date)
}

@Observable
final class HomeModel:
    HomeModelStateProtocol,
    HomeModelActionProtocol
{
    private var scores: [Score]

    private(set) var isLatest: Bool
    var songCount: Int { scores.count }
    var recentScores: [Score] {
        Array(
            scores
                .sorted {
                    ($0.updatedAt, $0.createdAt) > ($1.updatedAt, $1.createdAt)
                }
                .prefix(3)
        )
    }
    var sortedScores: [Score] {
        let comparator: (Score, Score) -> Bool = {
            self.isLatest
                ? $0.createdAt > $1.createdAt
                : $0.createdAt < $1.createdAt
        }
        return scores.sorted(by: comparator)
    }
    private(set) var selectedScore: Score?
    private(set) var scoreToDelete: Score?
    private(set) var playhead: Playhead

    init() {
        self.scores = []

        self.isLatest = true
        self.selectedScore = nil
        self.scoreToDelete = nil
        self.playhead = Playhead(isPlaying: false, elapsedTime: .zero)
    }

    func setScores(_ scores: [Score]) {
        self.scores = scores
    }

    func setLatest(_ isLatest: Bool) {
        self.isLatest = isLatest
    }

    func selectScore(_ score: Score?) {
        self.selectedScore = score
    }

    func setScoreToDelete(_ score: Score?) {
        self.scoreToDelete = score
    }

    func updatePlayhead(_ playhead: Playhead) {
        self.playhead = playhead
    }

    func updateTitle(_ score: Score, title: String) {
        score.updateTitle(title)
    }

    func setUpdatedAt(_ score: Score, updatedAt: Date) {
        score.setUpdatedAt(updatedAt)
    }
}
