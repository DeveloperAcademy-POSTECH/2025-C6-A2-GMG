//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct ControllerButton<Label: View>: View {
    @Environment(\.palette) private var palette
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
            ZStack {
                label
                    .transition(.blurReplace)
            }
            .geometryGroup()
            .foregroundStyle(
                isDark
                    ? palette.primaryButtonLabel
                    : palette.secondaryButtonLabel
            )
            .background(
                isDark
                    ? palette.primaryButtonBackground
                    : palette.secondaryButtonBackground,
                in: RoundedRectangle(cornerRadius: 18)
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .background(
                isDark ? Color.black : Color.white,
                in: RoundedRectangle(cornerRadius: 18)
            )
        }
        .buttonStyle(.bouncy)
    }

    func columns(_ columns: Int) -> some View {
        self
            .gridCellColumns(max(1, columns))
    }
}

#Preview {
    @Previewable @State var isDark: Bool = false

    ControllerButton(isDark: isDark) {
        isDark.toggle()
    } label: {
        Text(isDark ? "Dark" : "Light")
            .id(isDark)
    }
    .frame(maxWidth: 320, maxHeight: 160)
}
