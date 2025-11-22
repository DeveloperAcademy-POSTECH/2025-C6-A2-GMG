//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
internal import UIKit

protocol ChordProgressModelStateProtocol {
    var score: Score { get }
    var isEditMode: Bool { get }
    var playhead: Playhead { get }
    var isMuted: Bool { get }
    var currentChordCell: ChordCell? { get }
    var selectedChordCell: ChordCell? { get }
    var canUndo: Bool { get }
    var canRedo: Bool { get }
    var segmentSlices: [[ChordSegmentSlice]] { get }
}

protocol ChordProgressModelActionProtocol: AnyObject {
    func setEditMode(_ isEditMode: Bool)
    func updatePlayhead(_ playhead: Playhead)
    func setMuted(_ isMuted: Bool)
    func selectChordCell(_ chordCell: ChordCell?)
    func replaceChord(with candidate: Chord?, for cell: ChordCell)
    func updateTitle(_ title: String)
    func updateCanUndo(_ canUndo: Bool)
    func updateCanRedo(_ canRedo: Bool)
}

struct ChordSegmentSlice: Identifiable {
    let chordCell: ChordCell
    let durationInSegment: TimeInterval

    var id: TimeInterval {
        chordCell.startTime
    }
}

@Observable
final class ChordProgressModel:
    ChordProgressModelStateProtocol,
    ChordProgressModelActionProtocol
{
    private(set) var score: Score
    private(set) var isEditMode: Bool
    private(set) var playhead: Playhead
    private(set) var isMuted: Bool
    private(set) var currentChordCell: ChordCell?
    private(set) var selectedChordCell: ChordCell?
    private(set) var canUndo: Bool
    private(set) var canRedo: Bool
    private(set) var segmentSlices: [[ChordSegmentSlice]]

    init(score: Score) {
        self.score = score
        self.isEditMode = false
        self.playhead = Playhead(isPlaying: false, elapsedTime: .zero)
        self.isMuted = false
        self.currentChordCell = nil
        self.selectedChordCell = nil
        self.canUndo = false
        self.canRedo = false
        self.segmentSlices = []

        rebuildSegmentSlices()
    }

    func setEditMode(_ isEditMode: Bool) {
        self.isEditMode = isEditMode
    }

    func updatePlayhead(_ playhead: Playhead) {
        if self.playhead != playhead {
            self.playhead = playhead

            if let currentChordCellIndex: Int =
                score.retrieveCellIndexBy(time: playhead.elapsedTime + 0.01),
                let currentChordCell: ChordCell =
                    score.retrieveChordCellBy(cellIndex: currentChordCellIndex)
            {
                self.currentChordCell = currentChordCell
            }
        }
    }

    func setMuted(_ isMuted: Bool) {
        self.isMuted = isMuted
    }

    func selectChordCell(_ chordCell: ChordCell?) {
        self.selectedChordCell = chordCell
    }

    func replaceChord(with selectedCandidate: Chord?, for cell: ChordCell) {
        guard let cellIndex: Int = score.retrieveCellIndexBy(time: cell.startTime),
            let originalCell: ChordCell = score.retrieveChordCellBy(cellIndex: cellIndex)
        else {
            return
        }

        let previousChord: Chord? = originalCell.chord
        if previousChord == selectedCandidate {
            return
        }

        score.updateChordCellBy(cellIndex: cellIndex, chord: selectedCandidate)
        rebuildSegmentSlices()
        updateSelectedCell(at: cellIndex)
    }

    func updateTitle(_ title: String) {
        score.updateTitle(title)
    }

    func updateCanUndo(_ canUndo: Bool) {
        self.canUndo = canUndo
    }

    func updateCanRedo(_ canRedo: Bool) {
        self.canRedo = canRedo
    }

    private func updateSelectedCell(at index: Int) {
        guard let updatedCell = score.retrieveChordCellBy(cellIndex: index) else {
            return
        }

        selectedChordCell = updatedCell
    }

    /// 스코어 전체에 대해 세그먼트별 코드 조각을 다시 계산한다.
    private func rebuildSegmentSlices() {
        let chordCells = score.retrieveAllChordCells()
        let segmentCount = Int(ceil(score.totalDuration / Constants.segmentDuration))

        guard segmentCount > 0 else {
            segmentSlices = []
            return
        }

        var newSlices: [[ChordSegmentSlice]] = []

        for index in 0..<segmentCount {
            newSlices.append(
                buildChordSlices(
                    index: index,
                    chordCells: chordCells,
                    totalDuration: score.totalDuration,
                    segmentDuration: Constants.segmentDuration
                ))
        }

        segmentSlices = newSlices
    }

    /// 특정 세그먼트 구간과 겹치는 코드 셀을 찾아,
    /// UI에서 사용할 `ChordSegmentSlice` 배열로 변환한다.
    private func buildChordSlices(
        index: Int,
        chordCells: [ChordCell],
        totalDuration: TimeInterval,
        segmentDuration: TimeInterval
    ) -> [ChordSegmentSlice] {
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

            return ChordSegmentSlice(chordCell: cell, durationInSegment: durationInSegment)
        }
    }
}
