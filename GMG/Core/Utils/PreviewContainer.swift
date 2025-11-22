//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct PreviewContainer<Content: View>: View {
    @State private var diContainer: DIContainer
    @State private var router: Router
    private let content: Content

    init(
        @ViewBuilder content: (Router) -> Content
    ) {
        let diContainer: DIContainer = DIContainer(isStoredInMemoryOnly: true)
        let router: Router = Router(diContainer: diContainer)

        self.diContainer = diContainer
        self.router = router

        self.content = content(router)

        prepareSampleData()
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            content
                .navigationDestination(for: RouteWrapper.self) { route in
                    router.view(route.route)
                        .zoomTransition(id: route.id, in: route.namespace)
                }
        }
    }

    private func prepareSampleData() {
        do {
            guard let scoreRepository: ScoreRepository = diContainer.makeScoreRepository() else {
                Logger.warning("Failed to create score repository")
                return
            }

            for _ in 0..<10 {
                let score: Score = Score.mock

                try scoreRepository.insert(score)
            }
        } catch {
            Logger.error(String(describing: error))
        }
    }
}

#Preview {
    PreviewContainer { router in

    }
}
