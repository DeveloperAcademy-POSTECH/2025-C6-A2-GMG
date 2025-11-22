//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

extension View {
    @ViewBuilder
    func font(_ customFont: CustomFont) -> some View {
        if #available(iOS 26.0, *) {
            self
                .font(customFont.font)
                .lineHeight(.multiple(factor: customFont.lineHeightMultiple))
        } else {
            self
                .font(customFont.font)
                .lineSpacing(customFont.size * 0.2)
        }
    }
}

extension View {
    func font(_ primary: LocalizedCustomFont, _ secondary: LocalizedCustomFont...) -> some View {
        self
            .modifier(LocalizedCustomFontModifier(primary: primary, secondary: secondary))
    }
}

extension View {
    func navigationBar<Leading: View, Center: View, Trailing: View>(
        isBackButtonHidden: Bool = false,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder center: () -> Center = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
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

extension View {
    func compatibleGlassEffect<S: InsettableShape>(in shape: S) -> some View {
        self
            .modifier(CompatibleGlassEffect(shape: shape))
    }
}

extension View {
    @ViewBuilder
    func zoomTransition(id: (any Hashable)?, in namespace: Namespace.ID?) -> some View {
        if let id, let namespace {
            self
                .navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}
