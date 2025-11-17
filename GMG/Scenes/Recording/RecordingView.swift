//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftData
import SwiftUI

struct RecordingView: View {
    @State private var model: RecordingModelStateProtocol
    @State private var intent: RecordingIntentProtocol
    private weak var router: Router?

    init(
        model: RecordingModelStateProtocol,
        intent: RecordingIntentProtocol,
        router: Router? = nil
    ) {
        self.model = model
        self.intent = intent
        self.router = router
    }

    var body: some View {
        ZStack {
            Color.bg1
                .ignoresSafeArea()

            VStack {
                RecordingTime(
                    isRecording: model.isRecording,
                    recordingTime: model.recordingTime
                )
                .padding(.top, 64)

                Spacer()
            }
            .navigationBar(leading: {}, center: {}, trailing: {})

            WaveForm(audioLevels: model.audioLevels)

            VStack {
                Spacer()

                Controller(
                    recordingURL: model.recordingURL,
                    isRecording: model.isRecording,
                    isPlaying: model.isPlaying,
                    recordAction: intent.onTapRecordButton,
                    stopRecordAction: intent.onTapStopRecordButton,
                    resetAction: intent.onTapShowResetConfirmationAlertButton,
                    playAction: {
                        guard let url = model.recordingURL else { return }

                        intent.onTapPlayButton(url)
                    },
                    stopPlayAction: intent.onTapStopPlayButton,
                    nextAction: {
                        guard let url = model.recordingURL else { return }

                        intent.onTapNextButton(url) {
                            guard let score = model.score else { return }

                            router?.popToRoot()

                            router?.push(.chordProgress(score: score))
                        }
                    },
                )
            }
            .padding()

            Countdown(countdown: model.countdown, skipAction: intent.onTapSkipButton)
        }
        .overlay {
            ZStack {
                if let scoreFactoryState = model.scoreFactoryState {
                    LoadingView(scoreFactoryState: scoreFactoryState)
                }
            }
            .animation(.default, value: model.scoreFactoryState)
        }
        .task {
            await intent.onAppear()
        }
        .alert(
            .requestMicrophoneAccessPermission,
            isPresented: .constant(model.isRecordPermissionAlertPresented)
        ) {
            Button(.openSettings) {
                intent.onTapOpenSettingsButton()
            }
            .keyboardShortcut(.defaultAction)
            Button(.cancel, role: .cancel) {
                intent.onTapRecordPermissionAlertCancelButton()
            }
        }
        .alert(
            .resetConfirmationAlert, isPresented: .constant(model.isResetConfirmationAlertPresented)
        ) {
            Button(.reset, role: .destructive) {
                intent.onTapResetButton()
            }
            Button(.cancel, role: .cancel) {
                intent.onTapResetConfirmationAlertCancelButton()
            }
        }
    }

    struct Countdown: View {
        let countdown: Int
        let skipAction: () -> Void

        var body: some View {
            ZStack {
                Color.black
                    .opacity(countdown > 0 ? 0.6 : 0.0)
                    .ignoresSafeArea()

                if countdown > 0 {
                    Text(countdown.formatted())
                        .font(
                            .custom(
                                Typography.WantedSansStd.Medium,
                                size: 128
                            )
                        )
                        .foregroundStyle(Color.white1)
                        .contentTransition(.numericText())

                    Button {
                        skipAction()
                    } label: {
                        Text(.skip)
                            .font(Typography.WantedSansStd.R6)
                            .underline()
                            .foregroundStyle(Color.white1)
                    }
                    .buttonStyle(.bouncy)
                    .offset(y: 144)
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
                            ? Color.red1
                            : Color.black3
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

            attributedString.foregroundColor = Color.black3

            if minute >= 10 {
                attributedString.foregroundColor = Color.black1
            } else if minute > 0 {
                let range =
                    attributedString.index(
                        attributedString.startIndex,
                        offsetByCharacters: 1
                    )..<attributedString.endIndex
                attributedString[range].foregroundColor = Color.black1
            } else if second >= 10 {
                let range =
                    attributedString.index(
                        attributedString.startIndex,
                        offsetByCharacters: 3
                    )..<attributedString.endIndex
                attributedString[range].foregroundColor = Color.black1
            } else if second > 0 {
                let range =
                    attributedString.index(
                        attributedString.startIndex,
                        offsetByCharacters: 4
                    )..<attributedString.endIndex
                attributedString[range].foregroundColor = Color.black1
            }

            return attributedString
        }
    }

    struct WaveForm: View {
        let audioLevels: [Float]

        private var paddedAudioLevels: [Float] {
            Array(
                repeating: .zero,
                count: max(0, 34 - audioLevels.count)
            ) + Array(audioLevels.suffix(34))
        }

        var body: some View {
            HStack(spacing: Spacing.xs) {
                ForEach(
                    Array(paddedAudioLevels.enumerated()),
                    id: \.offset
                ) { _, audioLevel in
                    let height: CGFloat = CGFloat(80 * audioLevel + 10)

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
        let recordingURL: URL?
        let isRecording: Bool
        let isPlaying: Bool
        let recordAction: () -> Void
        let stopRecordAction: () -> Void
        let resetAction: () -> Void
        let playAction: () -> Void
        let stopPlayAction: () -> Void
        let nextAction: () -> Void

        private var primaryButtonTitle: String {
            if isRecording {
                return String(localized: .stop)
            } else if isPlaying {
                return String(localized: .stop)
            } else if recordingURL != nil {
                return String(localized: .replay)
            }
            return String(localized: .record)
        }

        private var primaryButtonImage: ImageResource {
            if isRecording {
                return .stop
            } else if isPlaying {
                return .stop
            } else if recordingURL != nil {
                return .play
            }
            return .record
        }

        private var primaryButtonAction: () -> Void {
            if isRecording {
                return stopRecordAction
            } else if isPlaying {
                return stopPlayAction
            } else if recordingURL != nil {
                return playAction
            }
            return recordAction
        }

        var body: some View {
            Grid {
                GridRow {
                    if recordingURL != nil {
                        ControllerButton {
                            resetAction()
                        } label: {
                            VStack(spacing: Spacing.xs) {
                                Image(.reset)
                                    .renderingMode(.template)
                                Text(.reset)
                                    .font(Typography.WantedSansStd.M2)
                            }
                        }
                        .transition(
                            .scale(scale: 0.0, anchor: .leading)
                                .combined(with: .opacity)
                        )
                        .gridCellColumns(1)
                    }

                    ControllerButton(isDark: true) {
                        primaryButtonAction()
                    } label: {
                        VStack(spacing: Spacing.xs) {
                            Image(primaryButtonImage)
                                .renderingMode(.template)
                            Text(primaryButtonTitle)
                                .font(Typography.WantedSansStd.M2)
                        }
                    }
                    .gridCellColumns(2)

                    if recordingURL != nil {
                        ControllerButton {
                            nextAction()
                        } label: {
                            VStack(spacing: Spacing.xs) {
                                Image(.next)
                                    .renderingMode(.template)
                                Text(.next)
                                    .font(Typography.WantedSansStd.M2)
                            }
                        }
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
            .compatibleGlassEffect(in: RoundedRectangle(cornerRadius: 18))
            .animation(.default, value: recordingURL)
        }
    }
}

#Preview {
    PreviewContainer { router in
        router.view(.recording)
    }
}
