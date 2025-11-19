//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Lottie
import SwiftUI

struct LoadingView: View {
    let scoreFactoryState: ScoreFactoryState

    var body: some View {
        ZStack {
            Color.bg1
                .ignoresSafeArea()

            VStack(spacing: 144) {
                LottieView(animation: .named("LoadingLottie"))
                    .configure { view in
                        let width: Int = 800
                        let height: Int = 800

                        view.viewportFrame = CGRect(
                            x: (1920 - width) / 2,
                            y: (1080 - height) / 2,
                            width: width,
                            height: height
                        )
                    }
                    .playing(loopMode: .loop)
                    .frame(width: 196, height: 144)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(ScoreFactoryState.allCases, id: \.self) { state in
                        LoadingStateRow(state.localizedStringResource)
                            .disabled(scoreFactoryState.rawValue < state.rawValue)
                    }
                }
            }
        }
    }

    struct LoadingStateRow: View {
        @Environment(\.isEnabled) private var isEnabled: Bool

        let text: Text

        init<S: StringProtocol>(_ string: S) {
            self.text = Text(string)
        }

        init(_ resource: LocalizedStringResource) {
            self.text = Text(resource)
        }

        private var color: Color {
            isEnabled ? Color.black1 : Color.black7
        }

        var body: some View {
            HStack {
                Image(.checkmark)
                    .frame(width: 20, height: 20)
                    .background(color, in: Circle())
                text
                    .font(
                        .english(Typography.WantedSansStd.R6),
                        .korean(Typography.Pretendard.M6)
                    )
                    .foregroundStyle(color)
            }
        }
    }
}

#Preview {
    @Previewable @State var state: ScoreFactoryState = .hummingAnalysis

    PhaseAnimator(ScoreFactoryState.allCases) { state in
        LoadingView(scoreFactoryState: state)
    }
    .environment(\.locale, .init(languageCode: .english))
}
