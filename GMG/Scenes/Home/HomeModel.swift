//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftData

protocol HomeModelStateProtocol {
    var selectedScore: Score? { get }
    var isLatest: Bool { get }
    var allScores: [Score] { get }
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
    func fetchScores()
    func deleteScore(_ score: Score)
    func renameScore(_ score: Score, newTitle: String)
}

@Observable
final class HomeModel:
    HomeModelStateProtocol,
    HomeModelActionProtocol
{
    private(set) var selectedScore: Score?
    private(set) var isLatest: Bool
    private(set) var allScores: [Score]
    
    init() {
        self.selectedScore = nil
        self.isLatest = true
        self.allScores = []
    }
    
    var songCount: Int { allScores.count }
    var isScoresEmpty: Bool { allScores.isEmpty }
    
    var sortedScores: [Score] {
        allScores.sorted {
            if isLatest {
                if $0.updatedAt != $1.updatedAt {
                    return $0.updatedAt > $1.updatedAt
                } else {
                    return $0.createdAt > $1.createdAt
                }
            } else {
                if $0.createdAt != $1.createdAt {
                    return $0.createdAt < $1.createdAt
                } else {
                    return $0.updatedAt < $1.updatedAt
                }
            }
        }
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
    
    func fetchScores() {
        let storage = SwiftDataStorage.shared
        let context = storage.modelContext
        
        let scores = try? context?.fetch(FetchDescriptor<Score>())
        
        self.allScores = scores ?? []
    }
    
    func deleteScore(_ score: Score) {
        let storage = SwiftDataStorage.shared
        let context = storage.modelContext
        
        context?.delete(score)
        try? context?.save()
    }
    
    func renameScore(_ score: Score, newTitle: String) {
        let newTitle = newTitle
        guard newTitle.isEmpty == false, newTitle != score.title else { return }
        let storage = SwiftDataStorage.shared
        let context = storage.modelContext
        
        score.title = newTitle
        try? context?.save()
    }
}
