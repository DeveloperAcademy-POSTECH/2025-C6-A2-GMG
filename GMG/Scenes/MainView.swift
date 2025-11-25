//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftData
import SwiftUI

struct MainView: View {
    @State private var router: Router

    init() {
        let diContainer: DIContainer = DIContainer()
        let router: Router = Router(diContainer: diContainer)

        self.router = router
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            router.view(.home)
                .navigationDestination(for: RouteWrapper.self) { route in
                    router.view(route.route)
                    //                        .zoomTransition(id: route.id, in: route.namespace)
                }
        }
    }
}

#Preview {
    MainView()
}
