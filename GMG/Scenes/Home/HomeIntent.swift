//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftData

protocol HomeIntentProtocol {
    func loadScores(_ context: ModelContext)
    func setIsLatest(_ isLatest: Bool)
    func deleteScore(_ score: Score, context: ModelContext)
    func selectScore(_ score: Score?)
    func renameScore(_ score: Score, newTitle: String)
}

final class HomeIntent: HomeIntentProtocol {
    private var model: HomeModelActionProtocol?
    
    init(model: HomeModelActionProtocol) {
        self.model = model
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
}
