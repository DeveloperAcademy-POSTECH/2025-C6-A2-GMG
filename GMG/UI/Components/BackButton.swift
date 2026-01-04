//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct BackButton: View {
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.backward")
                .foregroundStyle(palette.navigationBarIcon)
        }
    }
}

#Preview {
    BackButton()
}
