//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct ErrorView: View {
    @Environment(\.palette) private var palette
    private let description: String?

    init(description: String? = nil) {
        self.description = description
    }

    var body: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()
            VStack {
                Text("Error")
                    .font(Typography.WantedSansStd.B13)
                Text(description ?? "Something went wrong")
                    .font(Typography.WantedSansStd.R5)

            }
            .foregroundStyle(palette.primaryText)
            .navigationBar(
                leading: {

                },
                center: {

                },
                trailing: {

                })
        }
    }
}

#Preview {
    PreviewContainer { router in
        ErrorView()
    }
}
