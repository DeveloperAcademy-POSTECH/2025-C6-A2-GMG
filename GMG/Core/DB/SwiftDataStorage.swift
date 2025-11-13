//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftData

@MainActor
final class SwiftDataStorage {
    private let modelContainer: ModelContainer?
    var modelContext: ModelContext? {
        modelContainer?.mainContext
    }

    static let shared: SwiftDataStorage = SwiftDataStorage()

    private init() {
        let configurations = ModelConfiguration(
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        self.modelContainer = try? ModelContainer(
            for: Score.self,
            configurations: configurations
        )
    }
}
