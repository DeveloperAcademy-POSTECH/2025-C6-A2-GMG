//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct ControllerContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        Grid(horizontalSpacing: Spacing.xs) {
            GridRow {
                content
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .compatibleGlassEffect(in: RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    ZStack {
        Color.blue
        ControllerContainer {
            ControllerButton {

            } label: {
                Text("Leading")
            }
            .columns(1)
            ControllerButton(isDark: true) {

            } label: {
                Text("Center")
            }
            .columns(2)
            ControllerButton {

            } label: {
                Text("Trailing")
            }
            .columns(1)
        }
        .frame(height: 160)
    }
}
