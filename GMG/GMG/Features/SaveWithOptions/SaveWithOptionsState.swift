//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

enum CDStyle: CaseIterable {
    case `default`
    case glow
    case blue
    case green
    case yellow
    case pink

    var imageResource: ImageResource {
        switch self {
        case .default:
            return ImageResource.cdDefault
        case .glow:
            return ImageResource.cdGlow
        case .blue:
            return ImageResource.cdBlue
        case .green:
            return ImageResource.cdGreen
        case .yellow:
            return ImageResource.cdYellow
        case .pink:
            return ImageResource.cdPink
        }
    }
}

enum SaveOption: CaseIterable {
    case cd
    case score
    case audioFile
}

struct SaveWithOptionsState {
    let title: String
    let selectedOption: SaveOption
    let selectedCDStyle: CDStyle
}

extension SaveWithOptionsState {
    func copy(
        title: String? = nil,
        selectedOption: SaveOption? = nil,
        selectedCDStyle: CDStyle? = nil,
    ) -> SaveWithOptionsState {
        return SaveWithOptionsState(
            title: title ?? self.title,
            selectedOption: selectedOption ?? self.selectedOption,
            selectedCDStyle: selectedCDStyle ?? self.selectedCDStyle
        )
    }
}

extension SaveWithOptionsState {
    static var mock: SaveWithOptionsState {
        SaveWithOptionsState(
            title: "",
            selectedOption: .cd,
            selectedCDStyle: .default
        )
    }
}
