//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct RouterModifier: PreviewModifier {
    static func makeSharedContext() async throws -> Router {
        return Router()
    }

    func body(content: Content, context: Router) -> some View {
        content
            .environment(context)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    static var routerModifier: Self = .modifier(RouterModifier())
}
