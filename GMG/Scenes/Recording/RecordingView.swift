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
            .navigationBar()

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
            if let scoreFactoryState = model.scoreFactoryState {
                LoadingView(scoreFactoryState: scoreFactoryState)
            }
        }
        .animation(.default, value: model.scoreFactoryState)
        .task {
            await intent.onAppear()
        }
        .alert(
            .requestMicrophoneAccessPermissionAlertTitle,
            isPresented: .constant(model.isRecordPermissionAlertPresented)
        ) {
            Button(.openSettings) {
                intent.onTapOpenSettingsButton()
            }
            .keyboardShortcut(.defaultAction)
            Button(.cancel, role: .cancel) {
                intent.onTapRecordPermissionAlertCancelButton()
            }
        } message: {
            Text(.requestMicrophoneAccessPermissionAlertDescription)
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
                        .offset(y: -80)

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

        private let spacing: CGFloat = 7
        private let capsuleWidth: CGFloat = 3
        private let capsuleMinHeight: CGFloat = 6
        private let capsuleMaxHeight: CGFloat = 80

        var body: some View {
            GeometryReader { geometry in
                let width: CGFloat = geometry.size.width

                let capsuleCount: Int = Int(width / (capsuleWidth + spacing))
                let levelsToDraw: [Float] = processLevels(count: capsuleCount)

                Canvas { context, size in
                    let startX: CGFloat =
                        (width - CGFloat(capsuleCount) * (capsuleWidth + spacing) + spacing) / 2

                    for (index, level) in levelsToDraw.enumerated() {
                        let safeLevel: CGFloat = min(max(CGFloat(level), 0.0), 1.0)

                        let barHeight: CGFloat =
                            safeLevel * (capsuleMaxHeight - capsuleMinHeight) + capsuleMinHeight

                        let xPosition: CGFloat = startX + CGFloat(index) * (capsuleWidth + spacing)
                        let yPosition: CGFloat = (size.height - barHeight) / 2

                        let rect: CGRect = CGRect(
                            x: xPosition,
                            y: yPosition,
                            width: capsuleWidth,
                            height: barHeight
                        )

                        let path: Path = Path(roundedRect: rect, cornerRadius: capsuleWidth / 2)
                        context.fill(path, with: .color(Color.black4))
                    }
                }
            }
            .frame(height: capsuleMaxHeight)
            .padding(.horizontal, Spacing.sm)
        }

        private func processLevels(count: Int) -> [Float] {
            guard count > 0 else { return [] }

            if audioLevels.count >= count {
                return Array(audioLevels.suffix(count))
            } else {
                let paddingCount = count - audioLevels.count
                return Array(repeating: 0.0, count: paddingCount) + audioLevels
            }
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

        private var primaryButtonTitle: LocalizedStringResource {
            if isRecording {
                return .stop
            } else if isPlaying {
                return .stop
            } else if recordingURL != nil {
                return .replay
            }
            return .record
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
            ControllerContainer {
                if recordingURL != nil {
                    ControllerButton {
                        resetAction()
                    } label: {
                        VStack(spacing: Spacing.xs) {
                            Image(.reset)
                                .renderingMode(.template)
                            Text(.reset)
                                .font(
                                    .english(Typography.WantedSansStd.M2),
                                    .korean(Typography.Pretendard.M5)
                                )
                        }
                    }
                    .columns(1)
                    .transition(
                        .scale(scale: 0.0, anchor: .leading)
                            .combined(with: .opacity)
                    )
                }

                ControllerButton(isDark: true) {
                    primaryButtonAction()
                } label: {
                    VStack(spacing: Spacing.xs) {
                        Image(primaryButtonImage)
                            .renderingMode(.template)
                        Text(primaryButtonTitle)
                            .font(
                                .english(Typography.WantedSansStd.M2),
                                .korean(Typography.Pretendard.M5)
                            )
                    }
                }
                .columns(2)

                if recordingURL != nil {
                    ControllerButton {
                        nextAction()
                    } label: {
                        VStack(spacing: Spacing.xs) {
                            Image(.next)
                                .renderingMode(.template)
                            Text(.next)
                                .font(
                                    .english(Typography.WantedSansStd.M2),
                                    .korean(Typography.Pretendard.M5)
                                )
                        }
                    }
                    .columns(1)
                    .transition(
                        .scale(scale: 0.0, anchor: .trailing)
                            .combined(with: .opacity)
                    )
                }
            }
            .frame(height: 140)
            .animation(.default, value: recordingURL)
        }
    }
}

#Preview {
    PreviewContainer { router in
        router.view(.recording)
    }
    .environment(\.locale, .init(languageCode: .english))
}
