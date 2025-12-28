//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct BackButton: View {
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.backward")
                .foregroundStyle(
                    colorScheme == .light
                        ? ComponentPalette.BackButton.light
                        : ComponentPalette.BackButton.dark
                )
        }
    }
}

#Preview {
    BackButton()
}
