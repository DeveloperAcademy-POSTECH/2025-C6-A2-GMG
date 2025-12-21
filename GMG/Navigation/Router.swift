//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

enum Route: Hashable {
    case home
    case recording
    case chordProgress(score: Score)
    case export(score: Score)
}

struct RouteWrapper: Hashable {
    let route: Route
    let id: AnyHashable?
    let namespace: Namespace.ID?

    init(route: Route, id: (any Hashable)? = nil, namespace: Namespace.ID? = nil) {
        self.route = route
        self.id = if let id { AnyHashable(id) } else { nil }
        self.namespace = namespace
    }
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
        path.append(RouteWrapper(route: route, id: nil, namespace: nil))
    }

    func push(_ route: Route, id: any Hashable, in namespace: Namespace.ID) {
        path.append(RouteWrapper(route: route, id: id, namespace: namespace))
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
                ErrorView(description: "Failed to create database")
            }
        case .chordProgress(let score):
            if let scoreRepository: ScoreRepository = diContainer.makeScoreRepository() {
                // FIXME: 코드 정제 결과물 확인을 위해 잠시 router 경로를 변경합니다.
                //                let model: ChordProgressModel = ChordProgressModel(score: score)
                //                let intent: ChordProgressIntent = ChordProgressIntent(
                //                    model: model, scoreRepository: scoreRepository)
                //
                //                ChordProgressView(model: model, intent: intent, router: self)
                let model: ChordProgressExperimentalModel = .init(score: score)
                let intent: ChordProgressExperimentalIntent = .init(
                    model: model,
                    scoreRepository: scoreRepository
                )

                ChordProgressExperimentalView(model: model, intent: intent, router: self)
            } else {
                ErrorView(description: "Failed to create database")
            }
        case .export(let score):
            let model: ExportModel = ExportModel(score: score)
            let intent: ExportIntent = ExportIntent(model: model)

            ExportView(model: model, intent: intent, router: self)
        }
    }
}
