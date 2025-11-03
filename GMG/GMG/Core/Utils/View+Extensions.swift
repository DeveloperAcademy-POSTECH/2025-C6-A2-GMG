//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

extension View {
    func font(_ customFont: CustomFont) -> some View {
        self
            .font(customFont.font)
            .lineHeight(.multiple(factor: customFont.lineHeightMultiple))
    }
}
