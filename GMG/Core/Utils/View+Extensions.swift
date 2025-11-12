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
    func navigationBar<Leading: View, Trailing: View>(
        _ title: String? = nil,
        isTitleEditable: Bool = false,
        onEnterTitle: ((String) -> Void)? = nil,
        isBackButtonHidden: Bool = false,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        VStack {
            NavigationBar(
                title,
                isBackButtonHidden: isBackButtonHidden,
                isTitleEditable: isTitleEditable,
                onEnterTitle: onEnterTitle
            ) {
                leading()
            } trailing: {
                trailing()
            }

            self
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
}
