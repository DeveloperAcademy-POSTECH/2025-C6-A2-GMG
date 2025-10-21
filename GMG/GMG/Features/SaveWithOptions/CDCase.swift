//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct CDCase: View {
    let title: String
    let date: Date
    let cdStyle: CDStyle

    var body: some View {
        ZStack {
            Image(.cdCase)
                .resizable()
                .scaledToFit()
            Image(cdStyle.imageResource)
                .resizable()
                .scaledToFit()
                .frame(width: 160)
                .offset(x: 10)
                .blur(radius: 0.5)
        }
        .clipShape(Rectangle())
        .overlay {
            Image(.cdCaseCover)
        }
        .overlay(alignment: .bottomTrailing) {
            VStack(spacing: .zero) {
                Text(title)
                    .font(
                        .custom(Typography.NeoDonggeunmoPro.FontName, size: 4)
                    )
                    .foregroundStyle(.gray6)
                Image(.barcode)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40)
                Text(dateString)
                    .font(
                        .custom(Typography.DOSGothic.FontName, size: 6)
                    )
                    .tracking(2)
                    .foregroundStyle(.gray6)
                    .offset(x: 2)
            }
            .offset(x: -Spacing.sm, y: -Spacing.sm)
        }
        .frame(width: 200)
    }

    private let dateFormatter = Date.VerbatimFormatStyle(
        format: "\(year: .defaultDigits)\(month: .twoDigits)\(day: .twoDigits)",
        timeZone: .autoupdatingCurrent,
        calendar: .autoupdatingCurrent
    )

    private var dateString: String {
        date.formatted(dateFormatter)
    }
}

#Preview {
    CDCase(title: "나의 웃음에게", date: Date(), cdStyle: .default)
}
