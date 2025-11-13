//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftData

protocol HomeModelStateProtocol {
    var selectedScore: Score? { get }
    var isLatest: Bool { get }
    var allScores: [Score] { get }
    var isPlaying: Bool { get }
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
    func startPlaying()
    func stopPlaying()
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
    private(set) var isPlaying: Bool
    private(set) var playhead: Playhead

    init() {
        self.selectedScore = nil
        self.isLatest = true
        self.allScores = []
        self.isPlaying = false
        self.playhead = Playhead(isPlaying: false, elapsedTime: .zero)
    }

    var songCount: Int { allScores.count }
    var isScoresEmpty: Bool { allScores.isEmpty }

    var sortedScores: [Score] {
        let comparator: (Score, Score) -> Bool = {
            self.isLatest
                ? ($0.updatedAt, $0.createdAt) > ($1.updatedAt, $1.createdAt)
                : ($0.createdAt, $0.updatedAt) < ($1.createdAt, $1.updatedAt)
        }

        return allScores.sorted(by: comparator)
    }

    var recentScores: [Score] {
        Array(sortedScores.prefix(3))
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
        let storage = SwiftDataStorage.shared
        let context = storage.modelContext

        score.title = newTitle
    }

    func startPlaying() {
        self.isPlaying = true
    }

    func stopPlaying() {
        self.isPlaying = false
    }

    func updatePlayhead(_ playhead: Playhead) {
        self.playhead = playhead

        if self.isPlaying != playhead.isPlaying {
            self.isPlaying = playhead.isPlaying
        }
    }
}
