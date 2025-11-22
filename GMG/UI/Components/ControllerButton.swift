//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct ControllerButton<Label: View>: View {
    let isDark: Bool
    let action: () -> Void
    let label: Label

    init(
        isDark: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.isDark = isDark
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button {
            action()
        } label: {
            label
                .foregroundStyle(
                    isDark ? Color.white1 : Color.black1
                )
                .geometryGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    isDark ? Color.black : Color.white,
                    in: RoundedRectangle(cornerRadius: 18)
                )
        }
        .buttonStyle(.bouncy)
    }
}

#Preview {
    ControllerButton {

    } label: {
        Text("Test")
    }
}
