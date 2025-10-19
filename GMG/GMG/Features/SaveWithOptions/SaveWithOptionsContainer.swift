//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

@Observable
final class SaveWithOptionsContainer {
    private(set) var state: SaveWithOptionsState

    init() {
        self.state = .mock
    }

    func send(_ intent: SaveWithOptionsIntent) {
        switch intent {
        case .setTitle(let title):
            setTitle(title)
        case .selectSaveOption(let saveOption):
            selectSaveOption(saveOption)
        case .selectCDStyle(let cdStyle):
            selectCDStyle(cdStyle)
        case .save:
            save()
        }
    }

    private func setTitle(_ title: String) {
        self.state = self.state.copy(title: title)
    }

    private func selectSaveOption(_ saveOption: SaveOption) {
        self.state = self.state.copy(selectedOption: saveOption)
    }

    private func selectCDStyle(_ cdStyle: CDStyle) {
        self.state = self.state.copy(selectedCDStyle: cdStyle)
    }

    private func save() {
        // TODO: - Save Implementation
    }
}
