//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct PreviewContainer<Content: View>: View {
    private let content: Content

    init(
        @ViewBuilder content: (Router) -> Content
    ) {
        let diContainer: DIContainer = DIContainer(isStoredInMemoryOnly: true)
        let router: Router = Router(diContainer: diContainer)

        self.content = content(router)
    }

    var body: some View {
        NavigationStack {
            content
        }
    }
}

#Preview {
    PreviewContainer { router in

    }
}
