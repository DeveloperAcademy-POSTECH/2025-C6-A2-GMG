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

    init() {
        self.path = NavigationPath()
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
            HomeView()
        case .recording:
            RecordingView()
        case .chordProgress(let score):
            ChordProgressView(score: score)
        case .export(let score):
            ExportView(score: score)
        }
    }
}
