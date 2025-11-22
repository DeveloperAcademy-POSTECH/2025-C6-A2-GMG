//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftUI

struct SegmentHandlers {
    let onTapChordCell: (ChordCell) -> Void
    let onTapChordCandidate: (Chord, ChordCell) -> Void
}

struct WaveformHandlers {
    let onTap: (TimeInterval) -> Void
    let onDragStart: (TimeInterval) -> Void
    let onDragChange: (TimeInterval) -> Void
    let onDragEnd: (TimeInterval) -> Void
}

struct Segment: View {
    let index: Int
    let totalDuration: TimeInterval
    let chordSlices: [ChordSegmentSlice]
    let segmentDuration: TimeInterval
    let currentChordCell: ChordCell?  // 재생 중인 코드 셀
    let selectedChordCell: ChordCell?  // 편집 모드에서 선택된 코드 셀
    let audioLevels: [Float]
    let elapsedTime: TimeInterval
    let segmentHandlers: SegmentHandlers
    let waveformHandlers: WaveformHandlers

    @Environment(\.editMode) private var editMode

    private let audioSampleInterval: TimeInterval = 0.1

    private var segmentStartTime: TimeInterval {
        TimeInterval(index) * segmentDuration
    }

    private var segmentEndTime: TimeInterval {
        segmentStartTime + segmentDuration
    }

    private var clampedSegmentEndTime: TimeInterval {
        min(segmentEndTime, totalDuration)
    }

    private var segmentAudioLevels: [Float] {
        guard !audioLevels.isEmpty else { return [] }

        guard clampedSegmentEndTime > segmentStartTime else { return [] }

        let startIndex: Int = max(
            0,
            Int(floor(segmentStartTime / audioSampleInterval))
        )
        let endIndex: Int = min(
            audioLevels.count,
            Int(ceil(clampedSegmentEndTime / audioSampleInterval))
        )

        guard startIndex < endIndex else { return [] }

        return Array(audioLevels[startIndex..<endIndex])
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            GeometryReader { proxy in
                let slices = chordSlices
                let totalSpacing = Spacing.xs * CGFloat(max(0, slices.count - 1))
                let availableWidth = proxy.size.width - totalSpacing

                HStack(spacing: Spacing.xs) {
                    ForEach(slices) { slice in
                        let widthRatio = slice.durationInSegment / max(1, segmentDuration)
                        let cellWidth = max(0, availableWidth * widthRatio)

                        if let chord = slice.chordCell.chord {
                            ChordCellButton(
                                chord: chord,
                                isShowDescription: widthRatio
                                    >= Constants.minimumChordCellWidthRatio,
                                isCurrentChord: currentChordCell?.startTime
                                    == slice.chordCell.startTime,
                                isSelected: selectedChordCell?.startTime
                                    == slice.chordCell.startTime
                            ) {
                                segmentHandlers.onTapChordCell(slice.chordCell)
                            }
                            .frame(width: cellWidth, height: 62)
                        } else {
                            Rectangle()
                                .foregroundStyle(Color.clear)
                                .frame(width: cellWidth, height: 62)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 62, maxHeight: 62)

            let showCandidates: Bool =
                editMode?.wrappedValue.isEditing == true
                && chordSlices.contains(where: {
                    $0.chordCell.startTime == selectedChordCell?.startTime
                })
                && selectedChordCell?.startTime ?? 0.0 >= segmentStartTime

            ChordCellCandidates(
                chordCell: selectedChordCell ?? ChordCell.empty,
                onTapChordCandidate: segmentHandlers.onTapChordCandidate
            )
            .frame(height: showCandidates ? 62 : 0)
            .scaleEffect(y: showCandidates ? 1.0 : 0.0)
            .opacity(showCandidates ? 1.0 : 0.0)

            GeometryReader { proxy in
                let segmentWidth =
                    proxy.size.width
                    * ((clampedSegmentEndTime - segmentStartTime)
                        / Constants.segmentDuration)

                VStack(spacing: Spacing.xs) {

                    Waveform(
                        width: segmentWidth,
                        amplitudes: segmentAudioLevels,
                        startTime: segmentStartTime,
                        endTime: clampedSegmentEndTime,
                        elapsedTime: elapsedTime,
                        onTap: waveformHandlers.onTap,
                        onDragStart: waveformHandlers.onDragStart,
                        onDragChange: waveformHandlers.onDragChange,
                        onDragEnd: waveformHandlers.onDragEnd
                    )

                    TimeRuler(
                        visibleWidth: segmentWidth,
                        startTime: segmentStartTime,
                        endTime: segmentEndTime,
                        dotCount: Int(segmentDuration * 2) - 1
                    )
                }
            }
            .frame(height: 55)
        }
        .animation(.default, value: editMode?.wrappedValue)
        .animation(.default, value: selectedChordCell?.startTime)
    }

    struct ChordCellCandidates: View {
        let chordCell: ChordCell
        let onTapChordCandidate: (Chord, ChordCell) -> Void

        var body: some View {
            ZStack {
                Color.black2

                HStack {
                    Spacer()

                    ForEach(Array(chordCell.chordCandidates.enumerated()), id: \.offset) {
                        (index, chord) in
                        ChordCandidateButton(
                            index: index,
                            chord: chord,
                            selectedChord: chordCell.chord,
                            onTapButton: { onTapChordCandidate(chord, chordCell) }
                        )
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .frame(minHeight: 62)
            .padding(.horizontal, -Spacing.md)
        }
    }

    struct ChordCandidateButton: View {
        let index: Int
        let chord: Chord
        let selectedChord: Chord?
        let onTapButton: () -> Void

        private var backgroundColor: Color {
            if selectedChord == chord {
                return .blue6
            } else if index == 0 || index == 1 {
                return .blue7
            } else {
                return .blue3
            }
        }

        var body: some View {
            Button {
                onTapButton()
            } label: {
                VStack {
                    Text(chord.description)
                        .font(Typography.WantedSansStd.R5)
                        .foregroundStyle(.white1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(.horizontal, Spacing.xs)
                .frame(minWidth: 60, maxWidth: 60, minHeight: 40, maxHeight: 40)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(backgroundColor)
                }
            }
        }
    }

    struct ChordCellButton: View {
        let chord: Chord
        let isShowDescription: Bool
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
                    return Color.blue6
                } else {
                    return Color.white1
                }
            }
        }

        var body: some View {
            Button {
                action()
            } label: {
                ZStack {
                    if isShowDescription {
                        ViewThatFits(in: .horizontal) {
                            /// CASE 1: one line
                            Text(chord.description)
                                .font(Typography.WantedSansStd.R7)

                            /// CASE 2: multi line (여유공간 있는 상태)
                            VStack(alignment: .center) {
                                Text("\(chord.root.description)\n\(chord.quality.description)")
                                    .multilineTextAlignment(.center)
                            }
                            .font(Typography.WantedSansStd.R5)

                            /// CASE 3: multi line (여유공간 없는 상태)
                            VStack(alignment: .center) {
                                Text("\(chord.root.description)\n\(chord.quality.description)")
                                    .multilineTextAlignment(.center)
                            }
                            .font(Typography.WantedSansStd.R1)
                        }
                        .foregroundStyle(foregroundColor)
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .padding(.horizontal, Spacing.xxs)
                .background(
                    backgroundColor,
                    in: RoundedRectangle(cornerRadius: 12)
                )
            }
            .buttonStyle(.bouncy)
        }
    }

    struct TimeRuler: View {
        let visibleWidth: CGFloat
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
            .mask {
                HStack {
                    Rectangle()
                        .frame(width: visibleWidth)

                    Spacer()
                }
            }
            .foregroundStyle(
                editMode?.wrappedValue.isEditing == true
                    ? Color.black5 : Color.black8
            )
            .padding(.horizontal, Spacing.xs)
        }
    }
}
