//  Copyright © 2026 ADA 4th GMG. All rights reserved.

import Combine
import SwiftUI

@Observable
final class ThemeManager {
    @AppStorage("selectedTheme") private var storedTheme: String = "basic"

    @Published var palette: Palette = .basic {
        didSet {
            switch palette {
            case .basic: storedTheme = "basic"
            case .next: storedTheme = "next"
            }
        }
    }

    init() {
        switch storedTheme {
        case "next": palette = .next
        default: palette = .basic
        }
    }

    func useBasic() {
        palette = .basic
    }

    func useNext() {
        palette = .next
    }

    func toggle() {
        palette = (palette == .basic) ? .next : .basic
    }
}
