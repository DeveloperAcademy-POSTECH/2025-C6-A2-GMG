//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct RecordingView: View {
    @State private var model: RecordingModelStateProtocol
    @State private var intent: RecordingIntentProtocol

    init() {
        let model: RecordingModel = RecordingModel()

        self.model = model
        self.intent = RecordingIntent(model: model)
    }

    var body: some View {
        ZStack {
            Color.Background.light
                .ignoresSafeArea()

            VStack {
                RecordingTime(
                    isRecording: model.isRecording,
                    recordingTime: model.recordingTime
                )
                .padding(.top, 64)

                Spacer()
            }
            .navigationBar(leading: {}, trailing: {})

            WaveForm(amplitudes: model.amplitudes)

            VStack {
                Spacer()

                Controller(
                    recordingUrl: model.recordingURL,
                    isRecording: model.isRecording,
                    isPlaying: model.isPlaying,
                    recordAction: intent.onTapRecordButton,
                    stopRecordAction: intent.onTapStopRecordButton,
                    resetAction: intent.onTapResetButton,
                    playAction: {
                        if let url = model.recordingURL {
                            intent.onTapPlayButton(url)
                        }
                    },
                    stopPlayAction: intent.onTapStopPlayButton
                )
            }
            .padding()

            Countdown(countdown: model.countdown)
        }

    }

    struct Countdown: View {
        let countdown: Int

        var body: some View {
            ZStack {
                Color.black
                    .opacity(countdown > 0 ? 0.6 : 0.0)
                    .ignoresSafeArea()

                if countdown > 0 {
                    Text(countdown.formatted())
                        .font(
                            .custom(
                                Typography.WantedSansStd.M1.fontName,
                                size: 128
                            )
                        )
                        .foregroundStyle(Color.Text.white)
                        .contentTransition(.numericText())
                }
            }
            .animation(.default, value: countdown)
        }
    }

    struct RecordingTime: View {
        let isRecording: Bool
        let recordingTime: TimeInterval

        var body: some View {
            HStack {
                Circle()
                    .foregroundStyle(
                        (isRecording
                            && Int(
                                recordingTime.truncatingRemainder(dividingBy: 2)
                            )
                                == 1)
                            ? Color.RecordingIndicator.active
                            : Color.RecordingIndicator.inactive
                    )
                    .frame(width: 14, height: 14)
                    .offset(y: -20)
                Text(time)
                    .font(Typography.WantedSansStd.R11)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.default, value: recordingTime)
            }
        }

        private var time: AttributedString {
            let minute: Int = Int(recordingTime / 60)
            let second: Int = Int(
                recordingTime.truncatingRemainder(dividingBy: 60)
            )

            var attributedString: AttributedString = AttributedString(
                String(format: "%02d:%02d", minute, second)
            )

            attributedString.foregroundColor = Color.Text.gray

            if minute >= 10 {
                attributedString.foregroundColor = Color.Text.black
            } else if minute > 0 {
                let range =
                    attributedString.index(
                        attributedString.startIndex,
                        offsetByCharacters: 1
                    )..<attributedString.endIndex
                attributedString[range].foregroundColor = Color.Text.black
            } else if second >= 10 {
                let range =
                    attributedString.index(
                        attributedString.startIndex,
                        offsetByCharacters: 3
                    )..<attributedString.endIndex
                attributedString[range].foregroundColor = Color.Text.black
            } else if second > 0 {
                let range =
                    attributedString.index(
                        attributedString.startIndex,
                        offsetByCharacters: 4
                    )..<attributedString.endIndex
                attributedString[range].foregroundColor = Color.Text.black
            }

            return attributedString
        }
    }

    struct WaveForm: View {
        let amplitudes: [Float]
        
        private var paddedAmplitudes: [Float] {
            Array(
                repeating: .zero,
                count: max(0, 34 - amplitudes.count)
            ) + Array(amplitudes.suffix(34))
        }

        var body: some View {
            HStack(spacing: Spacing.xs) {
                ForEach(
                    paddedAmplitudes.enumerated(),
                    id: \.0
                ) { _, amplitude in
                    let height: CGFloat = clampHeight(CGFloat(amplitude) * 5000)
                    

                    Capsule()
                        .foregroundStyle(Color.gray)
                        .frame(width: 3, height: height)
                }
            }
        }
        
        private func clampHeight(_ height: CGFloat) -> CGFloat {
            return min(90, max(10, height))
        }
    }

    struct Controller: View {
        let recordingUrl: URL?
        let isRecording: Bool
        let isPlaying: Bool
        let recordAction: () -> Void
        let stopRecordAction: () -> Void
        let resetAction: () -> Void
        let playAction: () -> Void
        let stopPlayAction: () -> Void

        var body: some View {
            var primaryButtonTitle: String = "Record"
            var primaryButtonIconName: String = "circle.fill"
            var primaryButtonAction: () -> Void = recordAction
            if isRecording {
                primaryButtonTitle = "Stop"
                primaryButtonIconName = "stop.fill"
                primaryButtonAction = stopRecordAction
            } else if isPlaying {
                primaryButtonTitle = "Stop"
                primaryButtonIconName = "stop.fill"
                primaryButtonAction = stopPlayAction
            } else if recordingUrl != nil {
                primaryButtonTitle = "Replay"
                primaryButtonIconName = "play.fill"
                primaryButtonAction = playAction
            }

            return Grid {
                GridRow {
                    if recordingUrl != nil {
                        ControllerButton(
                            title: "Reset",
                            iconName: "arrow.clockwise",
                            action: resetAction,
                            isDark: false
                        )
                        .transition(
                            .scale(scale: 0.0, anchor: .leading)
                                .combined(with: .opacity)
                        )
                        .gridCellColumns(1)
                    }

                    ControllerButton(
                        title: primaryButtonTitle,
                        iconName: primaryButtonIconName,
                        action: primaryButtonAction,
                        isDark: true
                    )
                    .gridCellColumns(2)

                    if recordingUrl != nil {
                        ControllerButton(
                            title: "Next",
                            iconName: "chevron.forward",
                            action: {},
                            isDark: false
                        )
                        .transition(
                            .scale(scale: 0.0, anchor: .trailing)
                                .combined(with: .opacity)
                        )
                        .gridCellColumns(1)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: 140)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
            .animation(.default, value: recordingUrl)
        }

        struct ControllerButton: View {
            let title: String
            let iconName: String
            let action: () -> Void
            let isDark: Bool

            var body: some View {
                Button {
                    action()
                } label: {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: iconName)
                            .frame(minWidth: 20)
                        Text(title)
                            .font(Typography.WantedSansStd.M2)
                    }
                    .foregroundStyle(
                        isDark ? Color.Text.white : Color.Text.black
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        isDark ? Color.black : Color.white,
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                }
                .buttonStyle(.bouncy)
            }
        }
    }
}

#Preview {
    RecordingView()
}
