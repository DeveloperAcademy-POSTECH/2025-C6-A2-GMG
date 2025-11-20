//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct ChordInSegment {
    /// Segment에서 보여줄 코드
    ///
    /// `nil`일 경우 빈칸으로 보입니다.
    let chord: Chord?

    /// Segment 안에서 차지하는 비율(0.0~1.0)
    let proportion: Double
}

extension ChordInSegment {
    static func convert(score: Score, segmentDuration: TimeInterval = 5) -> [[ChordInSegment]] {
        let chordCells: [ChordCell] = score.chordCells
        let segmentCount: Int = Int(score.totalDuration / segmentDuration) + 1

        var segments: [[ChordInSegment]] = []
        for index in 0..<segmentCount {
            let startTime: TimeInterval = segmentDuration * TimeInterval(index)
            let endTime: TimeInterval = startTime + segmentDuration

            var cellsInSegment: [ChordCell] = chordCells.filter {
                startTime <= $0.startTime && $0.startTime < endTime
            }

            if let firstCell: ChordCell = cellsInSegment.first,
                startTime < firstCell.startTime
            {
                if let lastCellInPreviousSegment: ChordCell =
                    chordCells.last(where: { $0.startTime < startTime })
                {
                    cellsInSegment.insert(lastCellInPreviousSegment, at: 0)
                } else {
                    cellsInSegment.insert(
                        .init(
                            chord: nil,
                            chordCandidates: [],
                            startTime: startTime,
                            duration: .zero
                        ),
                        at: 0
                    )
                }
            } else if cellsInSegment.isEmpty,
                let lastCellInPreviousSegment: ChordCell =
                    chordCells.last(where: { $0.startTime < startTime })
            {
                cellsInSegment.insert(lastCellInPreviousSegment, at: 0)
            }

            guard cellsInSegment.isEmpty == false else {
                // 셀이 비어 있다면 비어 있는 코드 추가
                segments.append([.init(chord: nil, proportion: 1.0)])
                continue
            }

            var segment: [ChordInSegment] = []

            for cellIndex in cellsInSegment.indices {
                let currentCell: ChordCell = cellsInSegment[cellIndex]

                guard cellsInSegment.indices.contains(cellIndex + 1) else {  // 마지막 셀
                    if score.totalDuration < endTime {  // 마지막 세그먼트
                        let duration: TimeInterval =
                            score.totalDuration - max(startTime, currentCell.startTime)
                        let proportion: Double = duration / segmentDuration

                        segment.append(.init(chord: currentCell.chord, proportion: proportion))

                        let remainProportion: Double =
                            (endTime - score.totalDuration) / segmentDuration

                        segment.append(.init(chord: nil, proportion: remainProportion))
                    } else {
                        let duration: TimeInterval = endTime - max(startTime, currentCell.startTime)
                        let proportion: Double = duration / segmentDuration

                        segment.append(.init(chord: currentCell.chord, proportion: proportion))
                    }

                    continue
                }

                let nextCell: ChordCell = cellsInSegment[cellIndex + 1]

                let duration: TimeInterval =
                    nextCell.startTime - max(startTime, currentCell.startTime)
                let proportion: Double = duration / segmentDuration

                segment.append(.init(chord: currentCell.chord, proportion: proportion))
            }

            segments.append(segment)
        }

        return segments
    }
}

struct ChordSheetView: View {
    let title: String
    let key: Key
    let segmentStartTime: TimeInterval
    let segmentDuration: TimeInterval
    let segments: [[ChordInSegment]]

    var body: some View {
        ZStack {
            Color.white1
                .ignoresSafeArea()

            VStack(spacing: 30) {
                ScoreInformationView(title: title, key: key)

                VStack(spacing: 20) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                        let startTime: TimeInterval =
                            segmentStartTime + segmentDuration * TimeInterval(index)
                        let endTime: TimeInterval = startTime + segmentDuration

                        SegmentView(
                            startTime: startTime,
                            endTime: endTime,
                            chordInSegments: segment
                        )
                    }
                }
                .frame(minHeight: 500)

                LogoView()
                    .padding(.top, 30)
            }
            .padding(Spacing.md)
        }
    }

    /// ImageRenderer를 사용할 때는 반드시 `@MainActor`에서 실행되어야 합니다.
    /// 그렇지 않을 경우 런타임 크래시가 발생합니다.
    @MainActor
    var uiImage: UIImage? {
        let ratio: CGFloat = 393 / 852

        let height: CGFloat = 852
        let width: CGFloat = ratio * height

        let renderer = ImageRenderer(
            content:
                self
                .frame(width: width, height: height)
        )

        renderer.scale = 3.0

        return renderer.uiImage
    }
}

extension ChordSheetView {
    struct ScoreInformationView: View {
        let title: String
        let key: Key

        var body: some View {
            VStack(spacing: Spacing.md) {
                Text(title)
                    .font(.custom(Typography.WantedSansStd.Bold, size: 40))
                Text("\(key.description) Key")
                    .font(Typography.WantedSansStd.R7)
            }
            .foregroundStyle(Color.black1)
        }
    }

    struct SegmentView: View {
        let startTime: TimeInterval
        let endTime: TimeInterval
        let chordInSegments: [ChordInSegment]

        private var dotCount: Int {
            max(0, Int(2 * (endTime - startTime) - 1))
        }

        var body: some View {
            VStack(spacing: Spacing.xs) {
                Grid {
                    GridRow {
                        ForEach(Array(chordInSegments.enumerated()), id: \.offset) {
                            index, chordInSegment in
                            Group {
                                if let chord: Chord = chordInSegment.chord {
                                    ChordInSegmentView(chord: chord)
                                } else {
                                    Color.clear
                                }
                            }
                            .frame(height: 62)
                            .gridCellColumns(
                                max(1, Int((chordInSegment.proportion * 100).rounded(.down))))
                        }
                    }
                }

                TimeRulerView(startTime: startTime, endTime: endTime, dotCount: dotCount)
            }
        }
    }

    struct ChordInSegmentView: View {
        let chord: Chord

        var body: some View {
            Text(chord.description)
                .font(Typography.WantedSansStd.R7)
                .foregroundStyle(Color.black1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black9)
                }
        }
    }

    struct TimeRulerView: View {
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
            .foregroundStyle(Color.black7)
            .padding(.horizontal, Spacing.xs)
        }
    }

    struct LogoView: View {
        var body: some View {
            Image(.sheetLogo)
        }
    }
}

#Preview {
    let score: Score = Score.mock
    let segments: [[ChordInSegment]] = ChordInSegment.convert(score: score)

    ChordSheetView(
        title: score.title,
        key: score.key,
        segmentStartTime: 0,
        segmentDuration: 5,
        segments: Array(segments[0..<min(segments.count, 5)])
    )
}
