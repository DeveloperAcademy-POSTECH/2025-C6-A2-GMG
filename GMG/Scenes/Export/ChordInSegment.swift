//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

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
                        .init(chord: nil, chordCandidates: [], startTime: startTime, duration: .zero), at: 0)
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

                if proportion < 0.01 {  // UI 상에 그려질 수 없는 크기일 경우
                    continue
                }
                segment.append(.init(chord: currentCell.chord, proportion: proportion))
            }

            segments.append(segment)
        }

        return segments
    }
}
