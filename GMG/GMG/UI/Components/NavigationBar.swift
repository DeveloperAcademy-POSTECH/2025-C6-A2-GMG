//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct NavigationBar<Leading: View, Trailing: View>: View {
    let title: String?
    let isBackButtonHidden: Bool
    let leading: Leading
    let trailing: Trailing

    init(
        _ title: String? = nil,
        isBackButtonHidden: Bool = false,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.isBackButtonHidden = isBackButtonHidden
        self.leading = leading()
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
            .buttonStyle(NavigationBarButtonStyle())

            if let title {
                Text(title)
                    .font(Typography.WantedSansStd.R6)
                    .foregroundStyle(Color.Text.black)
            }
        }
        .padding(Spacing.md)
    }
}

#Preview {
    NavigationBar("Test") {

    } trailing: {

    }
}
