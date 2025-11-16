//  Copyright © 2025 ADA 4th GMG. All rights reserved.

final class DIContainer {
    private let swiftDataStorage: SwiftDataStorage?

    init(
        isStoredInMemoryOnly: Bool = false
    ) {
        self.swiftDataStorage = try? SwiftDataStorage(isStoredInMemoryOnly: isStoredInMemoryOnly)
    }

    func makeScoreRepository() -> ScoreRepository? {
        guard let swiftDataStorage else { return nil }

        return SwiftDataScoreRepository(storage: swiftDataStorage)
    }
}
