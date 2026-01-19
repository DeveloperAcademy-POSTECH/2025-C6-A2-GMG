//  Copyright © 2026 ADA 4th GMG. All rights reserved.

import Observation
import SwiftUI

enum Theme: String {
    case basic
    case next

    var palette: Palette {
        switch self {
        case .basic: return .basic
        case .next: return .next
        }
    }
}

@Observable
final class ThemeManager {
    @ObservationIgnored
    @AppStorage("selectedTheme") private var storedTheme: String = "basic"

    var theme: Theme = .basic {
        didSet {
            storedTheme = theme.rawValue
        }
    }

    var palette: Palette {
        theme.palette
    }

    init() {
        theme = Theme(rawValue: storedTheme) ?? .basic
    }

    func useBasic() {
        theme = .basic
    }

    func useNext() {
        theme = .next
    }

    func toggle() {
        theme = (theme == .basic) ? .next : .basic
    }
}
