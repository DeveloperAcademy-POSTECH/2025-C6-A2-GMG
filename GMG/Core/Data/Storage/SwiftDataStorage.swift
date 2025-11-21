//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftData

typealias ScoreSchema = ScoreSchemaV1

final class SwiftDataStorage {
    private let container: ModelContainer
    var context: ModelContext {
        container.mainContext
    }

    init(
        isStoredInMemoryOnly: Bool = false
    ) throws {
        let configuration: ModelConfiguration = ModelConfiguration(
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )

        self.container = try ModelContainer(
            for: Schema(ScoreSchema.models),
            configurations: configuration
        )
    }
}
