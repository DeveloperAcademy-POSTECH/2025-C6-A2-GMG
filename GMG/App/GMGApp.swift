//
//  GMGApp.swift
//  GMG
//
//  Created by 나현흠 on 10/17/25.
//

import SwiftUI
import SwiftData

@main
struct GMGApp: App {
    @State private var router: Router
    
    init() {
        self.router = Router()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                HomeView()
                    .navigationDestination(for: Route.self) { route in
                        router.view(route)
                    }
            }
            .environment(router)
            .modelContainer(for: Score.self, isUndoEnabled: true)
        }
    }
}
