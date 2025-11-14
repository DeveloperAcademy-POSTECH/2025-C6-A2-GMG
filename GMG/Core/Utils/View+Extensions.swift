//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

extension View {
    func font(_ customFont: CustomFont) -> some View {
        self
            .font(customFont.font)
            .lineHeight(.multiple(factor: customFont.lineHeightMultiple))
    }
}

extension View {
    func navigationBar<Leading: View, Center: View, Trailing: View>(
        isBackButtonHidden: Bool = false,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder center: () -> Center,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        VStack {
            NavigationBar<Leading, Center, Trailing>(
                isBackButtonHidden: isBackButtonHidden,
                leading: leading,
                center: center,
                trailing: trailing
            )

            self
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
}
