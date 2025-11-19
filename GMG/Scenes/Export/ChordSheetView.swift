//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct ChordSheetView: View {
    let score: Score

    var body: some View {
        ZStack {
            Color.white1
                .ignoresSafeArea()

            VStack {
                VStack(spacing: Spacing.md) {
                    Text(score.title)
                        .font(.custom(Typography.WantedSansStd.Bold, size: 40))
                    Text("\(score.key.description) Key")
                        .font(Typography.WantedSansStd.R7)
                }
                .foregroundStyle(Color.black1)

                VStack {

                }
                .frame(minHeight: 490)

                Image(.sheetLogo)
            }
        }
    }
}

extension ChordSheetView {
    struct ChordCellView: View {
        let chordCell: ChordCell
        let duration: TimeInterval

        var body: some View {
            RoundedRectangle(cornerRadius: <#T##CGFloat#>)
            Text(chordCell.chord?.description ?? "")
        }
    }
}

#Preview {
    ChordSheetView(score: .mock)
}
