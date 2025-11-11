//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

protocol HomeIntentProtocol {
    func loadScores()
    func toggleSortOrder()
    func deleteScore(_ score: Score)
    func selectScore(_ score: Score?)
    func renameScore(_ score: Score, newTitle: String)
}

final class HomeIntent: HomeIntentProtocol {
    private var model: HomeModelActionProtocol?
    
    init(model: HomeModelActionProtocol) {
        self.model = model
    }
    
    func loadScores() {
        model?.fetchScores()
    }
    
    func toggleSortOrder() {
        model?.toggleIsLatest()
    }
    
    func deleteScore(_ score: Score) {
        model?.deleteScore(score)
    }
    
    func selectScore(_ score: Score?) {
        model?.setSelectedScore(score)
    }
    
    func renameScore(_ score: Score, newTitle: String) {
        model?.renameScore(score, newTitle: newTitle)
    }
}
