//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct ErrorView: View {
    private let description: String?

    init(description: String? = nil) {
        self.description = description
    }

    var body: some View {
        ZStack {
            Color.bg1
                .ignoresSafeArea()

            VStack {
                Text("Error")
                    .font(Typography.WantedSansStd.B13)
                Text(description ?? "Something went wrong")
                    .font(Typography.WantedSansStd.R5)

            }
            .foregroundStyle(Color.black1)
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
