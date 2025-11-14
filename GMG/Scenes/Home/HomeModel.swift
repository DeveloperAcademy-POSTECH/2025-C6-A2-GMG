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
    func fetchScores(_ context: ModelContext)
    func deleteScore(_ score: Score, context: ModelContext)
    func renameScore(_ score: Score, newTitle: String)
    func updatePlayhead(_ playhead: Playhead)
    func setUpdatedAt(_ score: Score, at date: Date)
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
                ? ($0.updatedAt, $0.createdAt) > ($1.updatedAt, $1.createdAt)
                : ($0.updatedAt, $0.createdAt) < ($1.updatedAt, $1.createdAt)
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

    func fetchScores(_ context: ModelContext) {
        do {
            let scores = try context.fetch(FetchDescriptor<Score>())
            self.allScores = scores
        } catch {
            self.allScores = []
        }
    }

    func deleteScore(_ score: Score, context: ModelContext) {
        context.delete(score)
        do {
            self.allScores.removeAll { $0.persistentModelID == score.persistentModelID }
            if selectedScore?.persistentModelID == score.persistentModelID {
                selectedScore = nil
            }
        }
    }

    func renameScore(_ score: Score, newTitle: String) {
        let newTitle = newTitle
        guard newTitle.isEmpty == false, newTitle != score.title else { return }

        score.title = newTitle
    }

    func updatePlayhead(_ playhead: Playhead) {
        self.playhead = playhead
    }

    func setUpdatedAt(_ score: Score, at date: Date = .now) {
        score.updatedAt = date

        self.allScores = self.allScores
    }
}
