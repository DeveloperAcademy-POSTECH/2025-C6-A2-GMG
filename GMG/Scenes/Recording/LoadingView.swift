//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct LoadingView: View {
    let scoreFactoryState: ScoreFactoryState

    var body: some View {
        ZStack {
            Color.bg1
                .ignoresSafeArea()

            VStack(spacing: 128) {
                Text("LOADING")
                    .font(Typography.WantedSansStd.B16)

                VStack(spacing: Spacing.xs) {
                    Text("Humming analysis in progress.")
                        .foregroundStyle(
                            scoreFactoryState.rawValue
                                >= ScoreFactoryState.hummingAnalysis.rawValue
                                ? Color.black1 : Color.black6
                        )
                    Text("AI is generating chords.")
                        .foregroundStyle(
                            scoreFactoryState.rawValue
                                >= ScoreFactoryState.chordGeneration.rawValue
                                ? Color.black1 : Color.black7
                        )
                    Text("Sheet music extraction in progress.")
                        .foregroundStyle(
                            scoreFactoryState.rawValue
                                >= ScoreFactoryState.sheetMusicExtraction
                                .rawValue ? Color.black1 : Color.black8
                        )
                }
                .font(Typography.WantedSansStd.R6)
            }
        }
    }
}

#Preview {
    LoadingView(scoreFactoryState: .hummingAnalysis)
}
