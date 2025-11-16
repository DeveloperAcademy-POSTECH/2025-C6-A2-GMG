//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct NavigationBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: 44, minHeight: 44)
            .scaleEffect(configuration.isPressed ? 1.1 : 1.0)
    }
}

#Preview {
    BackButton()
        .buttonStyle(NavigationBarButtonStyle())
}
