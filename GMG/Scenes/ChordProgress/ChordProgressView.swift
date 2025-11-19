//  Copyright © 2025 ADA 4th GMG. All rights reserved.

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

                let chordCandidateAction: (Chord, ChordCell) -> Void = { chord, chordCell in
                    intent.onTapCandidateChordCell(chord, in: chordCell, for: model.score)
                }

                SegmentsScrollView(
                    segmentDuration: 5.0,
                    totalDuration: model.score.totalDuration,
                    segmentSlices: model.segmentSlices,
                    currentChordCell: model.currentChordCell,
                    selectedChordCell: model.selectedChordCell,
                    chordCellAction: intent.onTapChordCell,
                    chordCandidateAction: intent.onTapCandidateChordCell,
                    onTapWaveform: intent.onTapWaveform,
                    onDragWaveformStart: intent.onDragWaveformStart,
                    onDragWaveformChange: intent.onDragWaveformChange,
                    onDragWaveformEnd: intent.onDragWaveformEnd,
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
                    String(localized: .enterTitle),
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
                    title: String(localized: .sheet),
                    isSelected: !isEditMode,
                    namespace: namespace
                ) {
                    isEditMode = false
                }

                ToggleButton(
                    title: String(localized: .edit),
                    isSelected: isEditMode,
                    namespace: namespace
                ) {
                    isEditMode = true
                }
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
            .animation(.default, value: isEditMode)
        }

        struct ToggleButton: View {
            let title: String
            let isSelected: Bool
            let namespace: Namespace.ID
            let action: () -> Void

            var body: some View {
                Button {
                    action()
                } label: {
                    Text(title)
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
                                    .fill(Color.blue4)
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

        var body: some View {
            Grid {
                GridRow {
                    ControllerButton {
                        stopAction()
                    } label: {
                        Image(.stop)
                            .renderingMode(.template)
                            .frame(width: 24, height: 24)
                    }
                    .gridCellColumns(1)

                    ControllerButton(isDark: true) {
                        primaryButtonAction()
                    } label: {
                        Image(primaryButtonImage)
                            .renderingMode(.template)
                    }
                    .gridCellColumns(3)

                    ControllerButton {
                        muteAction(!isMuted)
                    } label: {
                        Image(isMuted ? .waveform : .piano)
                            .renderingMode(.template)
                            .frame(width: 24, height: 24)
                    }
                    .gridCellColumns(1)
                }
            }
            .padding()
            .frame(maxHeight: 96)
            .compatibleGlassEffect(in: RoundedRectangle(cornerRadius: 18))
        }
    }

    struct SegmentsScrollView: View {
        let segmentDuration: TimeInterval
        let totalDuration: TimeInterval
        let segmentSlices: [Int: [ChordSegmentSlice]]
        let currentChordCell: ChordCell?
        let selectedChordCell: ChordCell?
        let chordCellAction: (ChordCell) -> Void
        let chordCandidateAction: (Chord, ChordCell) -> Void
        let onTapWaveform: (TimeInterval) -> Void
        let onDragWaveformStart: (TimeInterval) -> Void
        let onDragWaveformChange: (TimeInterval) -> Void
        let onDragWaveformEnd: (TimeInterval) -> Void
        let audioLevels: [Float]
        let elapsedTime: TimeInterval

        var body: some View {
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(
                        0..<Int(ceil(totalDuration / segmentDuration)),
                        id: \.self
                    ) { index in
                        Segment(
                            index: index,
                            totalDuration: totalDuration,
                            chordSlices: segmentSlices[index] ?? [],
                            segmentDuration: segmentDuration,
                            currentChordCell: currentChordCell,
                            selectedChordCell: selectedChordCell,
                            chordCellAction: chordCellAction,
                            chordCandidateAction: chordCandidateAction,
                            onTapWaveform: onTapWaveform,
                            onDragWaveformStart: onDragWaveformStart,
                            onDragWaveformChange: onDragWaveformChange,
                            onDragWaveformEnd: onDragWaveformEnd,
                            audioLevels: audioLevels,
                            elapsedTime: elapsedTime
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
