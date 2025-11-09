//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct ChordProgressView: View {
    @Environment(Router.self) private var router: Router

    @State private var model: ChordProgressModelStateProtocol
    @State private var intent: ChordProgressIntentProtocol

    init(score: Score) {
        let model: ChordProgressModel = ChordProgressModel(score: score)

        self.model = model
        self.intent = ChordProgressIntent(model: model)
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
                    
                    HStack(spacing: 20){
                        EditController(
                            canUndo: model.canUndo
                            , canRedo: model.canRedo
                            , onTapUndo: intent.onTapUndoButton
                            , onTapRedo: intent.onTapRedoButton
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
                }
                .padding(Spacing.md)

                SegmentsScrollView(
                    segmentDuration: 5.0,
                    totalDuration: model.score.totalDuration,
                    chordCells: model.score.retrieveAllChordCells(),
                    currentChordCell: model.currentChordCell,
                    selectedChordCell: model.selectedChordCell,
                    chordCellAction: intent.onTapChordCell,
                    chordCandidateAction: intent.onTapCandidateChordCell
                )
            }
            .navigationBar(
                model.score.title,
                leading: {

                },
                trailing: {
                    Button {
                        router.push(.export)
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
                    playAction: intent.onTapPlayButton,
                    pauseAction: intent.onTapPauseButton,
                    stopAction: intent.onTapStopButton
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
                Button {
                    onTapUndo()
                } label: {
                    Image(ImageResource.undo)
                        .renderingMode(.template)
                        .foregroundStyle(
                            canUndo
                            ? .white1
                            : .black2
                        )
                }
                
                Button {
                    onTapRedo()
                } label: {
                    Image(ImageResource.redo)
                        .renderingMode(.template)
                        .foregroundStyle(
                            canRedo
                            ? .white1
                            : .black2
                        )
                }
            }
        }
    }
    
    struct EditModeToggle: View {
        @Binding var isEditMode: Bool
        @Namespace var namespace

        var body: some View {
            HStack(spacing: .zero) {
                ToggleButton(
                    title: "Sheet",
                    isSelected: !isEditMode,
                    namespace: namespace
                ) {
                    isEditMode = false
                }
                ToggleButton(
                    title: "Edit",
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
                        .font(Typography.WantedSansStd.R2)
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
        let playAction: () -> Void
        let pauseAction: () -> Void
        let stopAction: () -> Void

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

                    } label: {
                        Image(.guitar)
                            .renderingMode(.template)
                    }
                    .gridCellColumns(1)
                }
            }
            .padding()
            .frame(maxHeight: 96)
            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    struct SegmentsScrollView: View {
        let segmentDuration: TimeInterval
        let totalDuration: TimeInterval
        let chordCells: [ChordCell]
        let currentChordCell: ChordCell?
        let selectedChordCell: ChordCell?
        let chordCellAction: (ChordCell) -> Void
        let chordCandidateAction: (Int, ChordCell) -> Void

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
                            chordCells: chordCells,
                            segmentDuration: segmentDuration,
                            currentChordCell: currentChordCell,
                            selectedChordCell: selectedChordCell,
                            chordCellAction: chordCellAction,
                            chordCandidateAction: chordCandidateAction
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

    struct Segment: View {
        let index: Int
        let totalDuration: TimeInterval
        let chordCells: [ChordCell] // 전체 악보의 코드 셀 리스트
        let segmentDuration: TimeInterval
        let currentChordCell: ChordCell? // 재생 중인 코드 셀
        let selectedChordCell: ChordCell? // 편집 모드에서 선택된 코드 셀
        let chordCellAction: (ChordCell) -> Void
        let chordCandidateAction: (Int, ChordCell) -> Void
 
        @Environment(\.editMode) private var editMode

        private var segmentStartTime: TimeInterval {
            TimeInterval(index) * segmentDuration
        }

        private var segmentEndTime: TimeInterval {
            segmentStartTime + segmentDuration
        }

        private var targetChordCells: [ChordCell] {
            var targetChordCells: [ChordCell] = chordCells.filter {
                    chordCell in
                    segmentStartTime <= chordCell.startTime
                        && chordCell.startTime < segmentEndTime
                }
            
            let previousChordCell: ChordCell = {
                guard let previous = chordCells.filter({ c in c.startTime <= segmentStartTime }).last
                else {
                    return ChordCell(
                        chord: nil
                        , chordCandidates: []
                        , startTime: segmentStartTime
                    )
                }
                
                return previous
            }()
            
            /// 세그먼트에 코드가 없는 경우, 전 세그먼트의 마지막 코드를 사용
            if targetChordCells.isEmpty {
                targetChordCells = [previousChordCell]
            }
            
            /// 코드가 존재하고, 첫 코드가 segmentStartTime보다 늦게 시작하는 경우,
            ///  전 세그먼트의 마지막 코드를 사용
            if let firstStartTime = targetChordCells.first?.startTime
                , firstStartTime > segmentStartTime
            {
                targetChordCells.insert(previousChordCell, at: 0)
            }

            /// 오디오 파일의 끝 처리
            if index == Int(floor(totalDuration / segmentDuration))
                && totalDuration < segmentEndTime
            {
                targetChordCells.append(
                    ChordCell(
                        chord: nil,
                        chordCandidates: [],
                        startTime: totalDuration
                    )
                )
            }

            return targetChordCells
        }

        private var chordCellsWithDuration: [(chordCell: ChordCell, duration: TimeInterval)] {
            guard !targetChordCells.isEmpty else { return [] }

            var result: [(chordCell: ChordCell, duration: TimeInterval)] = []
            
            for index in 0..<targetChordCells.endIndex - 1 {
                let currentChordCell = targetChordCells[index]
                let nextChordCell = targetChordCells[index + 1]

                let clampedCurStartTime = max(currentChordCell.startTime, segmentStartTime)
                let clampedNextStartTime = min(nextChordCell.startTime, segmentEndTime)
                
                let curDuration = clampedNextStartTime - clampedCurStartTime
                let clampedDuration = min(segmentDuration, curDuration)
                
                result.append((
                    chordCell: currentChordCell,
                    duration: clampedDuration
                ))
            }

            guard let lastChordCell = targetChordCells.last else {
                return result
            }
            
            let clampedStartTime = max(lastChordCell.startTime, segmentStartTime)
            let clampedDuration = segmentEndTime - clampedStartTime
            
            result.append((
                chordCell: lastChordCell,
                duration: clampedDuration
            ))
            
            return result
        }

        var body: some View {
            VStack(spacing: Spacing.xs) {
                GeometryReader { proxy in
                    let totalSpacing = Spacing.xs * CGFloat(chordCellsWithDuration.count - 1)
                    let availableWidth = proxy.size.width - totalSpacing
                    
                    HStack(spacing: Spacing.xs) {
                        ForEach(chordCellsWithDuration, id: \.0) { (chordCell, duration) in
                            let widthRatio = duration / max(1, segmentDuration)
                            let cellWidth = max(1, availableWidth * widthRatio)
                            
                            ZStack {
                                if let chord = chordCell.chord {
                                    ChordCellButton(
                                        chord: chord,
                                        isCurrentChord: currentChordCell?
                                            .startTime
                                            == chordCell.startTime,
                                        isSelected: selectedChordCell?.startTime
                                            == chordCell.startTime
                                    ) {
                                        chordCellAction(chordCell)
                                    }
                                } else {
                                    Color.clear
                                }
                            }
                            .frame(width: cellWidth, height: 64)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 64, maxHeight: 64)

                let showCandidates: Bool =
                    editMode?.wrappedValue.isEditing == true
                    && targetChordCells.contains(where: {
                        $0.startTime == selectedChordCell?.startTime
                    })
                    && selectedChordCell?.startTime ?? 0.0 >= segmentStartTime

                ChordCellCandidates(
                    chordCell: selectedChordCell ?? ChordCell.empty,
                    onTapAction: chordCandidateAction
                )
                .frame(height: showCandidates ? 62 : 0)
                .scaleEffect(y: showCandidates ? 1.0 : 0.0)
                .opacity(showCandidates ? 1.0 : 0.0)

                Waveform()

                TimeRuler(
                    startTime: segmentStartTime,
                    endTime: segmentEndTime,
                    dotCount: Int(segmentDuration * 2) - 1
                )
            }
            .animation(.default, value: editMode?.wrappedValue)
            .animation(.default, value: selectedChordCell?.startTime)
        }

        struct ChordCellCandidates: View {
            let chordCell: ChordCell
            let onTapAction: (Int, ChordCell) -> Void

            var body: some View {
                ZStack {
                    Color.black2

                    HStack {
                        Spacer()
                        
                        ForEach(chordCell.chordCandidates.indices, id: \.self) { index in
                            let chord = chordCell.chordCandidates[index]
                            Button {
                                onTapAction(index, chordCell)
                            } label: {
                                VStack {
                                    Text(chord.description)
                                        .font(Typography.WantedSansStd.R5)
                                        .foregroundStyle(.white1)
                                }
                                .frame(minWidth: 60, minHeight: 40)
                                .background {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            chord.description == chordCell.chord?.description
                                                ? .blue6
                                                : .blue3
                                        )
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(minHeight: 62)
                .padding(.horizontal, -Spacing.md)
            }
        }

        struct ChordCellButton: View {
            let chord: Chord
            let isCurrentChord: Bool
            let isSelected: Bool
            let action: () -> Void

            @Environment(\.editMode) private var editMode

            private var foregroundColor: Color {
                if editMode?.wrappedValue.isEditing == true {
                    if isSelected {
                        return Color.white1
                    } else if isCurrentChord {
                        return Color.black1
                    } else {
                        return Color.white1
                    }
                } else {
                    if isCurrentChord {
                        return Color.white1
                    } else {
                        return Color.black1
                    }
                }
            }

            private var backgroundColor: Color {
                if editMode?.wrappedValue.isEditing == true {
                    if isSelected {
                        return Color.blue6
                    } else if isCurrentChord {
                        return Color.white1
                    } else {
                        return Color.black2
                    }
                } else {
                    if isCurrentChord {
                        return Color.blue4
                    } else {
                        return Color.white1
                    }
                }
            }

            var body: some View {
                Button {
                    action()
                } label: {
                    Text(chord.description)
                        .font(Typography.WantedSansStd.R7)
                        .foregroundStyle(
                            foregroundColor
                        )
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                        .background(
                            backgroundColor,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                }
                .buttonStyle(.bouncy)
            }
        }

        // TODO: Waveform 구현
        struct Waveform: View {
            @Environment(\.editMode) private var editMode

            var body: some View {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        editMode?.wrappedValue.isEditing == true
                            ? Color.black2 : Color.white2
                    )
                    .frame(height: 36)
            }
        }

        struct TimeRuler: View {
            let startTime: TimeInterval
            let endTime: TimeInterval
            let dotCount: Int

            @Environment(\.editMode) private var editMode

            var body: some View {
                HStack {
                    Text("\(startTime, specifier: "%.0f")s")
                        .font(Typography.WantedSansStd.R2)
                        .fixedSize()
                    ForEach(0..<dotCount, id: \.self) { _ in
                        Circle()
                            .frame(width: 2, height: 2)
                            .frame(maxWidth: .infinity)
                    }
                    Text("\(endTime, specifier: "%.0f")s")
                        .font(Typography.WantedSansStd.R2)
                        .fixedSize()
                }
                .foregroundStyle(
                    editMode?.wrappedValue.isEditing == true
                        ? Color.black5 : Color.black8
                )
                .padding(.horizontal, Spacing.xs)
            }
        }
    }
}

#Preview(traits: .routerModifier) {
    NavigationStack {
        ChordProgressView(score: .mock)
    }
}
