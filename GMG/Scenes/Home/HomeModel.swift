//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

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
    func setAllScores(_ scores: [Score])
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
    
    func setAllScores(_ scores: [Score]) {
        self.allScores = scores
    }
}
