//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

enum Route: Hashable {
    case home
    case recording
    case chordProgress(score: Score)
    case export(score: Score)
}

@Observable
final class Router {
    var path: NavigationPath

    private let diContainer: DIContainer

    init(diContainer: DIContainer) {
        self.path = NavigationPath()

        self.diContainer = diContainer
    }

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }

    @ViewBuilder
    func view(_ route: Route) -> some View {
        switch route {
        case .home:
            if let scoreRepository: ScoreRepository = diContainer.makeScoreRepository() {
                let model: HomeModel = HomeModel()
                let intent: HomeIntent = HomeIntent(model: model, scoreRepository: scoreRepository)

                HomeView(model: model, intent: intent, router: self)
            } else {
                ErrorView(description: "Failed to create database")
            }
        case .recording:
            if let scoreRepository: ScoreRepository = diContainer.makeScoreRepository() {
                let model: RecordingModel = RecordingModel()
                let intent: RecordingIntent = RecordingIntent(
                    model: model, scoreRepository: scoreRepository)

                RecordingView(model: model, intent: intent, router: self)
            } else {
                Text("Error")
            }
        case .chordProgress(let score):
            if let scoreRepository: ScoreRepository = diContainer.makeScoreRepository() {
                let model: ChordProgressModel = ChordProgressModel(score: score)
                let intent: ChordProgressIntent = ChordProgressIntent(
                    model: model, scoreRepository: scoreRepository)

                ChordProgressView(model: model, intent: intent, router: self)
            } else {
                Text("Error")
            }
        case .export:
            ExportView()
        }
    }
}
