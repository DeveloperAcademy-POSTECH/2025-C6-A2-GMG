//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftUI

struct ChordProgressView: View {
    @State private var model: ChordProgressModelStateProtocol
    @State private var intent: ChordProgressIntentProtocol
    private weak var router: Router?

    init(
        model: ChordProgressModelStateProtocol,
        intent: ChordProgressIntentProtocol,
        router: Router?
    ) {
        self.model = model
        self.intent = intent
        self.router = router
    }

    var body: some View {
        ZStack {
            Background()

            VStack(spacing: .zero) {
                HStack(alignment: .lastTextBaseline) {
                    ScoreInformation(
                        key: model.score.key,
                        totalDuration: model.score.totalDuration
                    )

                    Spacer()

                    HStack(spacing: 20) {
                        EditController(
                            canUndo: model.canUndo, canRedo: model.canRedo,
                            onTapUndo: intent.onTapUndoButton, onTapRedo: intent.onTapRedoButton
                        )
                        .opacity(model.isEditMode ? 1.0 : 0.0)

                        EditModeToggle(
                            isEditMode: Binding<Bool>(
                                get: {
                                    model.isEditMode
                                },
                                set: {
                                    intent.onTapEditModeToggle($0)
                                }
                            )
                        )
                    }
                    .layoutPriority(1)
                }
                .padding(Spacing.md)

                let onTapChordCandidate: (Chord, ChordCell) -> Void = { chord, chordCell in
                    intent.onTapCandidateChordCell(chord, in: chordCell, for: model.score)
                }

                SegmentsScrollView(
                    totalDuration: model.score.totalDuration,
                    segmentSlices: model.segmentSlices,
                    currentChordCell: model.currentChordCell,
                    selectedChordCell: model.selectedChordCell,
                    segmentHandlers: SegmentHandlers(
                        onTapChordCell: intent.onTapChordCell,
                        onTapChordCandidate: onTapChordCandidate
                    ),
                    waveformHandlers: WaveformHandlers(
                        onTap: intent.onTapWaveform,
                        onDragStart: intent.onDragWaveformStart,
                        onDragChange: intent.onDragWaveformChange,
                        onDragEnd: intent.onDragWaveformEnd
                    ),
                    audioLevels: model.score.audioLevels,
                    elapsedTime: model.playhead.elapsedTime
                )
            }
            .navigationBar(
                isBackButtonHidden: true,
                leading: {
                    Button {
                        router?.popToRoot()
                    } label: {
                        Image("Home")
                            .renderingMode(.template)
                            .foregroundStyle(
                                model.isEditMode == false
                                    ? Color.black1 : Color.white1
                            )
                    }
                },
                center: {
                    let onEnterTitle: (String) -> Void = { title in
                        intent.onEnterTitle(title, for: model.score)
                    }
                    NavigationTitle(
                        title: model.score.title,
                        onEnterTitle: onEnterTitle
                    )
                },
                trailing: {
                    Button {
                        router?.push(.export(score: model.score))
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            )
            .environment(\.colorScheme, model.isEditMode ? .dark : .light)

            VStack {
                Spacer()

                Controller(
                    isPlaying: model.playhead.isPlaying,
                    isMuted: model.isMuted,
                    playAction: intent.onTapPlayButton,
                    pauseAction: intent.onTapPauseButton,
                    stopAction: intent.onTapStopButton,
                    muteAction: intent.onTapMuteButton
                )
            }
            .padding()
        }
        .environment(
            \.editMode,
            .constant(model.isEditMode ? EditMode.active : EditMode.inactive)
        )
        .onAppear {
            intent.onAppear(model.score)
        }
        .onDisappear {
            intent.onDisappear()
        }
    }
}

extension ChordProgressView {
    struct NavigationTitle: View {
        @Environment(\.colorScheme) private var colorScheme: ColorScheme

        let title: String
        @State var titleDraft: String
        @State private var isTitleEditing = false
        @FocusState private var isTitleFieldFocused: Bool

        let onEnterTitle: (String) -> Void

        init(
            title: String,
            onEnterTitle: @escaping (String) -> Void
        ) {
            self.title = title
            self.titleDraft = title
            self.onEnterTitle = onEnterTitle
        }

        private func startTitleEditing() {
            titleDraft = title
            isTitleEditing = true
            DispatchQueue.main.async {
                isTitleFieldFocused = true
            }
        }

        private func finishEditingTitle() {
            isTitleEditing = false
            isTitleFieldFocused = false
            onEnterTitle(titleDraft)
        }

        var body: some View {
            ZStack(alignment: .center) {
                TextField(
                    LocalizedStringKey(LocalizedStringResource.enterTitle.key),
                    text: isTitleFieldFocused ? $titleDraft : .constant(title)
                )
                .multilineTextAlignment(.center)
                .font(Typography.WantedSansStd.R6)
                .foregroundStyle(
                    colorScheme == .light
                        ? Color.black1 : Color.white1
                )
                .focused($isTitleFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    finishEditingTitle()
                }
                .opacity(
                    isTitleFieldFocused ? 1 : 0
                )

                HStack(spacing: 5) {
                    Text(title)
                        .font(Typography.WantedSansStd.R6)
                        .foregroundStyle(
                            colorScheme == .light
                                ? Color.black4 : Color.black3
                        )
                        .opacity(
                            isTitleEditing ? 0 : 1
                        )

                    Image(.pencil)
                        .renderingMode(.template)
                        .foregroundColor(
                            colorScheme == .light
                                ? Color.black1
                                : Color.white1
                        )
                        .opacity(
                            isTitleEditing ? 0 : 1
                        )
                }
            }
            .onTapGesture {
                startTitleEditing()
            }
            .frame(width: 177, height: 26)
            .background {
                if isTitleEditing {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            colorScheme == .light
                                ? Color.white3 : Color.black7
                        )
                }
            }
        }
    }

    struct Background: View {
        @Environment(\.editMode) private var editMode

        private var backgroundColor: Color {
            if editMode?.wrappedValue.isEditing == true {
                Color.bg2
            } else {
                Color.bg1
            }
        }

        var body: some View {
            backgroundColor
                .ignoresSafeArea()
        }
    }

    struct ScoreInformation: View {
        let key: Key
        let totalDuration: TimeInterval

        @Environment(\.editMode) private var editMode

        private var minuteString: String {
            String(
                format: "%02d",
                Int(totalDuration / 60)
            )
        }

        private var secondString: String {
            String(
                format: "%02d",
                Int(totalDuration.truncatingRemainder(dividingBy: 60))
            )
        }

        var body: some View {
            HStack(alignment: .lastTextBaseline) {
                Text("\(key.description) Key")
                    .font(Typography.WantedSansStd.R6)
                Text("\(minuteString):\(secondString)")
                    .font(Typography.WantedSansStd.R4)
            }
            .foregroundStyle(
                editMode?.wrappedValue.isEditing == true
                    ? Color.white1 : Color.black1
            )
        }
    }

    struct EditController: View {
        let canUndo: Bool
        let canRedo: Bool
        let onTapUndo: () -> Void
        let onTapRedo: () -> Void

        var body: some View {
            HStack(spacing: 24) {
                EditControllerButton {
                    onTapUndo()
                } label: {
                    Image(.undo)
                        .renderingMode(.template)
                }
                .disabled(canUndo == false)

                EditControllerButton {
                    onTapRedo()
                } label: {
                    Image(.redo)
                        .renderingMode(.template)
                }
                .disabled(canRedo == false)
            }
        }

        struct EditControllerButton<Label: View>: View {
            @Environment(\.isEnabled) private var isEnabled: Bool

            let action: () -> Void
            @ViewBuilder let label: () -> Label

            var body: some View {
                Button {
                    action()
                } label: {
                    label()
                        .foregroundStyle(
                            isEnabled ? .white1 : .black2
                        )
                }
                .buttonStyle(.bouncy)
            }
        }
    }

    struct EditModeToggle: View {
        @Binding var isEditMode: Bool
        @Namespace var namespace

        var body: some View {
            HStack(spacing: .zero) {
                ToggleButton(
                    title: .sheet,
                    isSelected: !isEditMode,
                    namespace: namespace
                ) {
                    isEditMode = false
                }

                ToggleButton(
                    title: .edit,
                    isSelected: isEditMode,
                    namespace: namespace
                ) {
                    isEditMode = true
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .inset(by: isEditMode ? 0.2 : 0)
                    .fill(.white1)
            )
            .animation(.default, value: isEditMode)
        }

        struct ToggleButton: View {
            let title: Text
            let isSelected: Bool
            let namespace: Namespace.ID
            let action: () -> Void

            init<S: StringProtocol>(
                title: S,
                isSelected: Bool,
                namespace: Namespace.ID,
                action: @escaping () -> Void
            ) {
                self.title = Text(title)
                self.isSelected = isSelected
                self.namespace = namespace
                self.action = action
            }

            init(
                title: LocalizedStringResource,
                isSelected: Bool,
                namespace: Namespace.ID,
                action: @escaping () -> Void
            ) {
                self.title = Text(title)
                self.isSelected = isSelected
                self.namespace = namespace
                self.action = action
            }

            var body: some View {
                Button {
                    action()
                } label: {
                    title
                        .font(
                            .english(
                                isSelected
                                    ? Typography.WantedSansStd.B3 : Typography.WantedSansStd.R3),
                            .korean(
                                isSelected ? Typography.Pretendard.SB4 : Typography.Pretendard.R1)
                        )
                        .bold(isSelected)
                        .foregroundStyle(
                            isSelected ? Color.white1 : Color.black1
                        )
                        .padding(Spacing.xs)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue6)
                                    .matchedGeometryEffect(
                                        id: "Background",
                                        in: namespace
                                    )
                            }
                        }
                }
            }
        }
    }

    struct Controller: View {
        let isPlaying: Bool
        let isMuted: Bool
        let playAction: () -> Void
        let pauseAction: () -> Void
        let stopAction: () -> Void
        let muteAction: (Bool) -> Void

        private var primaryButtonImage: ImageResource {
            if isPlaying {
                return .pause
            } else {
                return .play
            }
        }

        private var primaryButtonAction: () -> Void {
            if isPlaying {
                return pauseAction
            } else {
                return playAction
            }
        }

        private var muteIcon: Image {
            if isMuted {
                return Image(systemName: "music.note")
            } else {
                return Image(.waveform)
            }
        }

        var body: some View {
            ControllerContainer {
                ControllerButton {
                    stopAction()
                } label: {
                    Image(.stop)
                        .renderingMode(.template)
                        .frame(width: 24, height: 24)
                }
                .columns(1)

                ControllerButton(isDark: true) {
                    primaryButtonAction()
                } label: {
                    Image(primaryButtonImage)
                        .renderingMode(.template)
                }
                .columns(3)

                ControllerButton {
                    muteAction(!isMuted)
                } label: {
                    muteIcon
                        .renderingMode(.template)
                        .frame(width: 24, height: 24)
                        .font(.system(size: 22, weight: .semibold))
                }
                .columns(1)
            }
            .frame(height: 92)
        }
    }

    struct SegmentsScrollView: View {
        let totalDuration: TimeInterval
        let segmentSlices: [[ChordSegmentSlice]]
        let currentChordCell: ChordCell?
        let selectedChordCell: ChordCell?
        let segmentHandlers: SegmentHandlers
        let waveformHandlers: WaveformHandlers
        let audioLevels: [Float]
        let elapsedTime: TimeInterval

        var body: some View {
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(Array(segmentSlices.enumerated()), id: \.offset) { index, slices in
                        Segment(
                            index: index,
                            totalDuration: totalDuration,
                            chordSlices: slices,
                            segmentDuration: Constants.segmentDuration,
                            currentChordCell: currentChordCell,
                            selectedChordCell: selectedChordCell,
                            audioLevels: audioLevels,
                            elapsedTime: elapsedTime,
                            segmentHandlers: segmentHandlers,
                            waveformHandlers: waveformHandlers
                        )
                    }
                }
                .safeAreaPadding(Spacing.md)
                .safeAreaPadding(.bottom, 128)
            }
            .mask {
                VStack(spacing: .zero) {
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: .clear, location: 0.0),
                            Gradient.Stop(color: .white, location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: Spacing.md)
                    Color.white
                }
                .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    PreviewContainer { router in
        router.view(.chordProgress(score: .mock))
    }
    .environment(\.locale, .init(languageCode: .english))
}
