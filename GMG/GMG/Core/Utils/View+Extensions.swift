//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

extension View {
    func font<T: CustomFont>(_ customFont: T) -> some View {
        self
            .font(.custom(T.FontName, size: customFont.size))
            .lineHeight(.multiple(factor: customFont.lineHeightMultiple))
    }
}
