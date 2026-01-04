//  Copyright © 2026 ADA 4th GMG. All rights reserved.

import SwiftUI

private struct PaletteKey: EnvironmentKey {
    static let defaultValue: Palette = .basic  // 기본값은 basic
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}
