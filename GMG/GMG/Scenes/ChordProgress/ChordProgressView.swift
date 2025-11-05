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
                .padding(Spacing.md)

                SegmentsScrollView(
                    segmentDuration: 5.0,
                    totalDuration: model.score.totalDuration,
                    chordCells: model.score.retrieveAllChordCells(),
                    currentChordCell: model.currentChordCell,
                    chordCellAction: intent.onTapChordCell
                )
            }
            .preferredColorScheme(model.isEditMode ? .dark : .light)
            .navigationBar(
                model.score.title,
                leading: {},
                trailing: {
                    Button {
                        router.push(.export)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            )

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
        @Environment(\.colorScheme) private var colorScheme: ColorScheme

        var body: some View {
            Group {
                if colorScheme == .light {
                    Color.bg1
                } else {
                    Color.bg2
                }
            }
            .ignoresSafeArea()
        }
    }

    struct ScoreInformation: View {
        let key: Key
        let totalDuration: TimeInterval

        @Environment(\.colorScheme) private var colorScheme: ColorScheme

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
                colorScheme == .light ? Color.black1 : Color.white1
            )
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

        var body: some View {
            Grid {
                GridRow {
                    ControllerButton {
                        stopAction()
                    } label: {
                        Image(.stop)
                            .renderingMode(.template)
                    }
                    .transition(
                        .scale(scale: 0.0, anchor: .leading)
                            .combined(with: .opacity)
                    )
                    .gridCellColumns(1)

                    Group {
                        if isPlaying {
                            ControllerButton(isDark: true) {
                                pauseAction()
                            } label: {
                                Image(.pause)
                                    .renderingMode(.template)
                            }

                        } else {
                            ControllerButton(isDark: true) {
                                playAction()
                            } label: {
                                Image(.play)
                                    .renderingMode(.template)
                            }
                        }
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
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    struct SegmentsScrollView: View {
        let segmentDuration: TimeInterval
        let totalDuration: TimeInterval
        let chordCells: [ChordCell]
        let currentChordCell: ChordCell?
        let chordCellAction: (ChordCell) -> Void

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
                            chordCellAction: chordCellAction
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
        let chordCells: [ChordCell]
        let segmentDuration: TimeInterval
        let currentChordCell: ChordCell?
        let chordCellAction: (ChordCell) -> Void

        private var segmentStartTime: TimeInterval {
            TimeInterval(index) * segmentDuration
        }

        private var segmentEndTime: TimeInterval {
            segmentStartTime + segmentDuration
        }

        private var filteredChordCells: [ChordCell] {
            var filteredChordCells: [ChordCell] = chordCells.filter {
                chordCell in
                segmentStartTime <= chordCell.startTime
                    && chordCell.startTime < segmentEndTime
            }

            /// 현재 세그먼트에 코드가 없을 경우 추가
            if filteredChordCells.isEmpty,
                let previousChordCell: ChordCell = chordCells.filter({
                    chordCell in
                    chordCell.startTime <= segmentStartTime
                }).last
            {
                filteredChordCells = [previousChordCell]
            }

            /// 현재 세그먼트에 이전 코드 셀이 남아 있는 경우 추가
            if let firstStartTime = filteredChordCells.first?.startTime,
                firstStartTime - segmentStartTime > 0
            {
                if let previousChordCell: ChordCell = chordCells.filter({
                    chordCell in
                    chordCell.startTime <= segmentStartTime
                }).last {
                    filteredChordCells =
                        [previousChordCell] + filteredChordCells
                } else {
                    filteredChordCells =
                        [
                            ChordCell(
                                chord: nil,
                                chordCandidates: [],
                                startTime: segmentStartTime
                            )
                        ] + filteredChordCells
                }
            }

            /// 마지막 세그먼트에서 오디오 길이보다 작을 경우
            if index == Int(floor(totalDuration / 5))
                && totalDuration < segmentEndTime
            {
                filteredChordCells.append(
                    ChordCell(
                        chord: nil,
                        chordCandidates: [],
                        startTime: totalDuration
                    )
                )
            }

            return filteredChordCells
        }

        private var chordCellsWithDuration:
            [(chordCell: ChordCell, duration: Int)]
        {
            guard !filteredChordCells.isEmpty else { return [] }

            var result: [(chordCell: ChordCell, duration: Int)] = []

            for index in 0..<filteredChordCells.endIndex - 1 {
                let currentChordCell: ChordCell = filteredChordCells[index]
                let nextChordCell: ChordCell = filteredChordCells[index + 1]

                let duration: Int = Int(
                    ((nextChordCell.startTime - segmentStartTime)
                        - (max(segmentStartTime, currentChordCell.startTime)
                            - segmentStartTime))
                        .rounded()
                )

                result.append(
                    (
                        chordCell: currentChordCell,
                        duration: min(Int(segmentDuration), max(1, duration))
                    )
                )
            }

            if let lastChordCell = filteredChordCells.last {
                let duration: Int = Int(
                    segmentDuration
                        - (lastChordCell.startTime - segmentStartTime).rounded()
                )

                result.append(
                    (
                        chordCell: lastChordCell,
                        duration: min(Int(segmentDuration), max(1, duration))
                    )
                )
            }

            return result
        }

        var body: some View {
            VStack(spacing: Spacing.xs) {
                Grid(horizontalSpacing: Spacing.xs) {
                    GridRow {
                        ForEach(
                            Array(chordCellsWithDuration.enumerated()),
                            id: \.0
                        ) { index, chordCellWithDuration in
                            let chordCell = chordCellWithDuration.chordCell
                            let duration = chordCellWithDuration.duration

                            ZStack {
                                if let chord = chordCell.chord {
                                    ChordCellButton(
                                        chord: chord,
                                        isSelected: currentChordCell?.startTime
                                            == chordCell.startTime
                                    ) {
                                        chordCellAction(chordCell)
                                    }
                                } else {
                                    Color.clear
                                }
                            }
                            .gridCellColumns(duration)
                        }
                    }
                }
                .frame(height: 64)

                Waveform()

                TimeRuler(
                    startTime: segmentStartTime,
                    endTime: segmentEndTime,
                    dotCount: Int(segmentDuration * 2) - 1
                )
            }
        }

        struct ChordCellButton: View {
            let chord: Chord
            let isSelected: Bool
            let action: () -> Void

            var body: some View {
                Button {
                    action()
                } label: {
                    Text(chord.description)
                        .font(Typography.WantedSansStd.R7)
                        .foregroundStyle(
                            isSelected ? Color.white1 : Color.black1
                        )
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                        .background(
                            isSelected ? Color.blue4 : Color.white,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                }
                .buttonStyle(.bouncy)
            }
        }

        // TODO: Waveform 구현
        struct Waveform: View {
            var body: some View {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        Color.white2
                    )
                    .frame(height: 36)
            }
        }

        struct TimeRuler: View {
            let startTime: TimeInterval
            let endTime: TimeInterval
            let dotCount: Int

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
                    Color.black5
                )
                .padding(.horizontal, Spacing.xs)
            }
        }
    }
}

#Preview(traits: .routerModifier) {
    ChordProgressView(score: .mock)
}
