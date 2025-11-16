//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct NavigationBar<Leading: View, Center: View, Trailing: View>: View {
    @Environment(\.colorScheme) private var colorScheme: ColorScheme

    let isBackButtonHidden: Bool
    let leading: Leading
    let center: Center
    let trailing: Trailing

    init(
        isBackButtonHidden: Bool = false,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder center: () -> Center,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.isBackButtonHidden = isBackButtonHidden
        self.leading = leading()
        self.center = center()
        self.trailing = trailing()
    }

    var body: some View {
        ZStack {
            HStack {
                if !isBackButtonHidden {
                    BackButton()
                }

                leading

                Spacer()

                trailing
            }

            center
        }
        .padding(Spacing.xs)
        .buttonStyle(NavigationBarButtonStyle())
    }
}

#Preview {
    NavigationBar {
        EmptyView()
    } center: {
        EmptyView()
    } trailing: {
        EmptyView()
    }
}
