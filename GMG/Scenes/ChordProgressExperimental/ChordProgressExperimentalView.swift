//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftUI

struct ChordProgressExperimentalView: View {
    @Namespace private var namespace: Namespace.ID

    @State private var model: ChordProgressExperimentalModelStateProtocol
    @State private var intent: ChordProgressExperimentalIntentProtocol
    // FIXME: 임시 실험용 상태 (다이아토닉 정제 확인 후 제거 예정)
    @State private var isRefinementEnabled: Bool = false
    @State private var refinedScore: Score?
    @State private var refinedSegmentSlices: [[ChordProgressExperimentalSegmentSlice]]?
    private weak var router: Router?

    init(
        model: ChordProgressExperimentalModelStateProtocol,
        intent: ChordProgressExperimentalIntentProtocol,
        router: Router?
    ) {
        self.model = model
        self.intent = intent
        self.router = router
    }

    var body: some View {
        let displayScore: Score =
            isRefinementEnabled
            ? (refinedScore ?? model.score)
            : model.score

        let displaySegmentSlices: [[ChordProgressExperimentalSegmentSlice]] =
            isRefinementEnabled
            ? (refinedSegmentSlices ?? model.segmentSlices)
            : model.segmentSlices

        let displayCurrentChordCell: ChordCell? = {
            guard
                let index =
                    displayScore.retrieveCellIndexBy(time: model.playhead.elapsedTime + 0.01)
            else { return nil }
            return displayScore.retrieveChordCellBy(cellIndex: index)
        }()

        ZStack {
            Background()

            VStack(spacing: .zero) {
                HStack(alignment: .lastTextBaseline) {
                    ScoreInformation(
                        key: displayScore.key,
                        totalDuration: displayScore.totalDuration
                    )

                    Spacer()

                    HStack(spacing: 20) {
                        EditController(
                            canUndo: model.canUndo, canRedo: model.canRedo,
                            onTapUndo: intent.onTapUndoButton, onTapRedo: intent.onTapRedoButton
                        )
                        .opacity(model.isEditMode && isRefinementEnabled == false ? 1.0 : 0.0)
                        .disabled(isRefinementEnabled)

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
                        .disabled(isRefinementEnabled)

                        RefinementToggle(
                            isOn: Binding<Bool>(
                                get: { isRefinementEnabled },
                                set: { handleRefinementToggle(isOn: $0) }
                            )
                        )
                    }
                    .layoutPriority(1)
                }
                .padding(Spacing.md)

                let onTapChordCandidate: (Chord, ChordCell) -> Void = { chord, chordCell in
                    guard isRefinementEnabled == false else { return }
                    intent.onTapCandidateChordCell(chord, in: chordCell, for: model.score)
                }

                SegmentsScrollView(
                    totalDuration: displayScore.totalDuration,
                    segmentSlices: displaySegmentSlices,
                    currentChordCell: displayCurrentChordCell,
                    selectedChordCell: isRefinementEnabled ? nil : model.selectedChordCell,
                    segmentHandlers: ChordProgressExperimentalSegmentHandlers(
                        onTapChordCell: { chordCell, time in
                            intent.onTapChordCell(chordCell, seekTime: time)
                        },
                        onTapChordCandidate: onTapChordCandidate
                    ),
                    waveformHandlers: ChordProgressExperimentalWaveformHandlers(
                        onTap: intent.onTapWaveform,
                        onDragStart: intent.onDragWaveformStart,
                        onDragChange: intent.onDragWaveformChange,
                        onDragEnd: intent.onDragWaveformEnd
                    ),
                    audioLevels: displayScore.audioLevels,
                    elapsedTime: model.playhead.elapsedTime
                )
            }
            .navigationBar(
                isBackButtonHidden: true,
                leading: {
                    Button {
                        router?.popToRoot()
                    } label: {
                        Image(.home)
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
            .constant(
                isRefinementEnabled
                    ? EditMode.inactive
                    : (model.isEditMode ? EditMode.active : EditMode.inactive)
            )
        )
        .onAppear {
            intent.onAppear(model.score)
        }
        .onDisappear {
            intent.onDisappear()
        }
    }
}

extension ChordProgressExperimentalView {
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
            Task { @MainActor in
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
                .onChange(of: titleDraft) {
                    if titleDraft.count > Constants.scoreTitleMaxLength {
                        titleDraft = String(titleDraft.prefix(Constants.scoreTitleMaxLength))
                    }
                }
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
            @Environment(\.locale) private var locale

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

            private var horizontalPadding: CGFloat {
                switch locale.language.languageCode {
                case .korean: return 12
                case .english: return 10
                default: return 10
                }
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
                        .padding(.vertical, 10)
                        .padding(.horizontal, horizontalPadding)
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
                        .id(isPlaying)
                }
                .columns(3)
                .animation(.default, value: isPlaying)

                ControllerButton {
                    muteAction(!isMuted)
                } label: {
                    muteIcon
                        .renderingMode(.template)
                        .frame(width: 24, height: 24)
                        .font(.system(size: 22, weight: .semibold))
                        .id(isMuted)
                }
                .columns(1)
                .animation(.default, value: isMuted)
            }
            .frame(height: 92)
        }
    }

    struct SegmentsScrollView: View {
        let totalDuration: TimeInterval
        let segmentSlices: [[ChordProgressExperimentalSegmentSlice]]
        let currentChordCell: ChordCell?
        let selectedChordCell: ChordCell?
        let segmentHandlers: ChordProgressExperimentalSegmentHandlers
        let waveformHandlers: ChordProgressExperimentalWaveformHandlers
        let audioLevels: [Float]
        let elapsedTime: TimeInterval

        var body: some View {
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(Array(segmentSlices.enumerated()), id: \.offset) { index, slices in
                        ChordProgressExperimentalSegment(
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

    struct RefinementToggle: View {
        @Binding var isOn: Bool

        var body: some View {
            Button {
                isOn.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                    Text("정제")
                        .font(
                            .english(Typography.WantedSansStd.R3),
                            .korean(Typography.Pretendard.SB3))
                }
                .foregroundStyle(isOn ? Color.white1 : Color.black1)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isOn ? Color.blue6 : Color.white1)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black2.opacity(0.1), lineWidth: isOn ? 0 : 1)
                        }
                }
            }
            .buttonStyle(.bouncy)
        }
    }
}

// MARK: - Temporary refinement helpers (remove after diatonic validation)
extension ChordProgressExperimentalView {
    fileprivate func handleRefinementToggle(isOn: Bool) {
        if isOn {
            let refined: Score = DiatonicChordRefiner.refine(score: model.score)
            refinedScore = refined
            refinedSegmentSlices = buildSegmentSlices(for: refined)
            intent.onTapEditModeToggle(false)
            isRefinementEnabled = true
            intent.onTapRefinementToggle(true, score: refined)
        } else {
            isRefinementEnabled = false
            refinedScore = nil
            refinedSegmentSlices = nil
            intent.onTapRefinementToggle(false, score: model.score)
        }
    }

    fileprivate func buildSegmentSlices(for score: Score)
        -> [[ChordProgressExperimentalSegmentSlice]]
    {
        let chordCells = score.retrieveAllChordCells()
        let segmentCount = Int(ceil(score.totalDuration / Constants.segmentDuration))

        guard segmentCount > 0 else { return [] }

        var slices: [[ChordProgressExperimentalSegmentSlice]] = []

        for index in 0..<segmentCount {
            slices.append(
                buildChordSlices(
                    index: index,
                    chordCells: chordCells,
                    totalDuration: score.totalDuration,
                    segmentDuration: Constants.segmentDuration
                )
            )
        }

        return slices
    }

    fileprivate func buildChordSlices(
        index: Int,
        chordCells: [ChordCell],
        totalDuration: TimeInterval,
        segmentDuration: TimeInterval
    ) -> [ChordProgressExperimentalSegmentSlice] {
        let segmentStartTime = TimeInterval(index) * segmentDuration
        let segmentEndTime = min(segmentStartTime + segmentDuration, totalDuration)

        guard segmentStartTime < segmentEndTime else { return [] }

        let overlapping = chordCells.filter { cell in
            let cellEndTime = cell.startTime + cell.duration
            return segmentStartTime < cellEndTime && cell.startTime < segmentEndTime
        }

        let targetCells: [ChordCell] =
            if overlapping.isEmpty {
                if let previous = chordCells.last(where: { $0.startTime <= segmentStartTime }) {
                    [previous]
                } else if let first = chordCells.first {
                    [first]
                } else {
                    []
                }
            } else {
                overlapping
            }

        return targetCells.compactMap { cell in
            let overlapStart = max(cell.startTime, segmentStartTime)
            let overlapEnd = min(cell.startTime + cell.duration, segmentEndTime)
            let durationInSegment = max(0, overlapEnd - overlapStart)
            let occupancyRatio = durationInSegment / max(1, segmentDuration)

            guard occupancyRatio > 0.02 else { return nil }

            return ChordProgressExperimentalSegmentSlice(
                chordCell: cell,
                durationInSegment: durationInSegment
            )
        }
    }
}

#Preview {
    PreviewContainer { router in
        router.view(.chordProgress(score: .mock))
    }
    .environment(\.locale, .init(languageCode: .english))
}
