//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftData

protocol HomeModelStateProtocol {
    var selectedScore: Score? { get }
    var isLatest: Bool { get }
    var allScores: [Score] { get }
    var playhead: Playhead { get }
    var songCount: Int { get }
    var isScoresEmpty: Bool { get }
    var sortedScores: [Score] { get }
    var recentScores: [Score] { get }
}

protocol HomeModelActionProtocol: AnyObject {
    func setSelectedScore(_ score: Score?)
    func setIsLatest(_ isLatest: Bool)
    func toggleIsLatest()
    func setAllScores(_ scores: [Score])
    func updateScore(_ score: Score)
    func updatePlayhead(_ playhead: Playhead)
}

@Observable
final class HomeModel:
    HomeModelStateProtocol,
    HomeModelActionProtocol
{
    private(set) var selectedScore: Score?
    private(set) var isLatest: Bool
    private(set) var allScores: [Score]
    private(set) var playhead: Playhead

    init() {
        self.selectedScore = nil
        self.isLatest = true
        self.allScores = []
        self.playhead = Playhead(isPlaying: false, elapsedTime: .zero)
    }

    var songCount: Int { allScores.count }
    var isScoresEmpty: Bool { allScores.isEmpty }

    var sortedScores: [Score] {
        let comparator: (Score, Score) -> Bool = {
            self.isLatest
                ? $0.createdAt > $1.createdAt
                : $0.createdAt < $1.createdAt
        }
        return allScores.sorted(by: comparator)
    }

    var recentScores: [Score] {
        allScores
            .sorted {
                ($0.updatedAt, $0.createdAt) > ($1.updatedAt, $1.createdAt)
            }
    }

    func setSelectedScore(_ score: Score?) {
        self.selectedScore = score
    }

    func setIsLatest(_ isLatest: Bool) {
        self.isLatest = isLatest
    }

    func toggleIsLatest() {
        self.isLatest.toggle()
    }

    func setAllScores(_ scores: [Score]) {
        self.allScores = scores
    }

    func updateScore(_ score: Score) {
        guard let index = allScores.firstIndex(where: { $0.id == score.id }) else { return }
        allScores[index] = score
    }

    func updatePlayhead(_ playhead: Playhead) {
        self.playhead = playhead
    }
}
