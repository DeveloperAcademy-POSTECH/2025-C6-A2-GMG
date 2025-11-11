//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftData

@Model
class Score {
    var id: UUID = UUID()
    var title: String
    var key: Key
    var audioUrl: URL
    var totalDuration: TimeInterval
    var createdAt: Date
    var updatedAt: Date
    var notes: [Note]
    var chordCells: [ChordCell]
    var audioLevels: [Float] // 0.1s초 간격으로 audio의 amplitude 값이 저장

    init(
        title: String,
        key: Key,
        audioUrl: URL,
        totalDuration: TimeInterval,
        createdAt: Date,
        updatedAt: Date,
        notes: [Note],
        chordCells: [ChordCell],  // 정렬되어 있어야 함
        audioLevels: [Float]
    ) {
        self.title = title
        self.key = key
        self.audioUrl = audioUrl
        self.totalDuration = totalDuration
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.notes = notes
        self.chordCells = chordCells
        self.audioLevels = audioLevels
    }

    func retrieveAllChordCells() -> [ChordCell] {
        return self.chordCells
    }

    func retrieveCellIndexBy(time: TimeInterval) -> Int? {
        let index: Int? = chordCells.lastIndex { chordCell in
            chordCell.startTime <= time
        }

        return index
    }

    func retrieveChordBy(time: TimeInterval) -> Chord? {
        guard let index: Int = retrieveCellIndexBy(time: time) else {
            return nil
        }

        guard let chordCell: ChordCell = retrieveChordCellBy(cellIndex: index)
        else {
            return nil
        }

        let chord: Chord? = chordCell.chord

        return chord
    }

    func retrieveChordCellBy(cellIndex: Int) -> ChordCell? {
        guard chordCells.indices.contains(cellIndex) else { return nil }

        return chordCells[cellIndex]
    }

    func updateChordCellBy(cellIndex: Int, chord: Chord?) {
        guard chordCells.indices.contains(cellIndex) else { return }

        let chordCell: ChordCell = chordCells[cellIndex]
        let newChordCell: ChordCell = ChordCell(
            chord: chord,
            chordCandidates: chordCell.chordCandidates,
            startTime: chordCell.startTime
        )

        chordCells[cellIndex] = newChordCell
    }
}

extension Score {
    static var mock: Score {
        Score(
            title: "Untitled",
            key: Key(root: .C),
            audioUrl: Bundle.main.bundleURL,
            totalDuration: 31.0,
            createdAt: Date(),
            updatedAt: Date(),
            notes: [],
            chordCells: [
                ChordCell(
                    chord: Chord(root: .C, quality: .maj),
                    chordCandidates: [Chord(root: .C, quality: .maj), Chord(root: .D, quality: .maj), Chord(root: .Ab, quality: .maj), Chord(root: .Gb, quality: .maj), Chord(root: .Eb, quality: .maj)],
                    startTime: 0.0
                ),
                ChordCell(
                    chord: Chord(root: .D, quality: .min),
                    chordCandidates: [Chord(root: .D, quality: .min), Chord(root: .D, quality: .maj), Chord(root: .Ab, quality: .maj), Chord(root: .Gb, quality: .maj), Chord(root: .Eb, quality: .maj)],
                    startTime: 2.5
                ),
                ChordCell(
                    chord: Chord(root: .E, quality: .dim),
                    chordCandidates: [Chord(root: .E, quality: .dim), Chord(root: .D, quality: .maj), Chord(root: .Ab, quality: .maj), Chord(root: .Gb, quality: .maj), Chord(root: .Eb, quality: .maj)],
                    startTime: 5.0
                ),
                ChordCell(
                    chord: Chord(root: .F, quality: .maj9),
                    chordCandidates: [Chord(root: .F, quality: .maj9), Chord(root: .D, quality: .maj), Chord(root: .Ab, quality: .maj), Chord(root: .Gb, quality: .maj), Chord(root: .Eb, quality: .maj)],
                    startTime: 11.3
                ),
                ChordCell(
                    chord: Chord(root: .Bb, quality: .maj),
                    chordCandidates: [Chord(root: .Bb, quality: .maj), Chord(root: .D, quality: .maj), Chord(root: .Ab, quality: .maj), Chord(root: .Gb, quality: .maj), Chord(root: .Eb, quality: .maj)],
                    startTime: 13.0
                ),
            ],
            audioLevels: [
                // 0s–3.0s: 선형 상승
                0.00, 0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21, 0.24, 0.27,
                0.30, 0.33, 0.36, 0.39, 0.42, 0.45, 0.48, 0.51, 0.54, 0.57,
                0.60, 0.63, 0.66, 0.69, 0.72, 0.75, 0.78, 0.81, 0.84, 0.87,

                // 3.0s–4.0s: 1초 정적(0 유지) #1
                0,0,0,0,0,0,0,0,0,0,

                // 4.0s–9.0s: 선형 상승 재개
                0.20, 0.23, 0.26, 0.29, 0.32, 0.35, 0.38, 0.41, 0.44, 0.47,
                0.50, 0.53, 0.56, 0.59, 0.62, 0.65, 0.68, 0.71, 0.74, 0.77,
                0.80, 0.83, 0.86, 0.89, 0.92, 0.95, 0.98, 1.00, 0.97, 0.94,
                0.91, 0.88, 0.85, 0.82, 0.79, 0.76, 0.73, 0.70, 0.67, 0.64,
                0.61, 0.58, 0.55, 0.52, 0.49, 0.46, 0.43, 0.40, 0.37, 0.34,

                // 9.0s–10.0s: 1초 정적(0 유지) #2
                0,0,0,0,0,0,0,0,0,0,

                // 10.0s–15.0s: 선형 상승/하강
                0.10, 0.13, 0.16, 0.19, 0.22, 0.25, 0.28, 0.31, 0.34, 0.37,
                0.40, 0.43, 0.46, 0.49, 0.52, 0.55, 0.58, 0.61, 0.64, 0.67,
                0.70, 0.73, 0.76, 0.79, 0.82, 0.85, 0.88, 0.91, 0.94, 0.97,
                1.00, 0.97, 0.94, 0.91, 0.88, 0.85, 0.82, 0.79, 0.76, 0.73,
                0.70, 0.67, 0.64, 0.61, 0.58, 0.55, 0.52, 0.49, 0.46, 0.43,

                // 15.0s–16.0s: 1초 정적(0 유지) #3
                0,0,0,0,0,0,0,0,0,0,

                // 16.0s–21.0s: 선형 상승/하강
                0.15, 0.18, 0.21, 0.24, 0.27, 0.30, 0.33, 0.36, 0.39, 0.42,
                0.45, 0.48, 0.51, 0.54, 0.57, 0.60, 0.63, 0.66, 0.69, 0.72,
                0.75, 0.78, 0.81, 0.84, 0.87, 0.90, 0.93, 0.96, 0.99, 1.00,
                0.97, 0.94, 0.91, 0.88, 0.85, 0.82, 0.79, 0.76, 0.73, 0.70,
                0.67, 0.64, 0.61, 0.58, 0.55, 0.52, 0.49, 0.46, 0.43, 0.40,

                // 21.0s–22.0s: 1초 정적(0 유지) #4
                0,0,0,0,0,0,0,0,0,0,

                // 22.0s–31.0s: 선형 패턴 + 중간중간 0 삽입
                0.12, 0.15, 0.18, 0.21, 0.24, 0.27, 0.30, 0.33, 0.36, 0.39,
                0.42, 0.45, 0.48, 0.51, 0.54, 0.57, 0.60, 0.63, 0.66, 0.69,
                // 자연스러운 드롭
                0.00, 0.00,
                0.50, 0.53, 0.56, 0.59, 0.62, 0.65, 0.68, 0.71,
                0.74, 0.77, 0.80, 0.83, 0.86, 0.89, 0.92, 0.95, 0.98, 1.00,
                // 짧은 무음 스파이크
                0.00,
                0.97, 0.94, 0.91, 0.88, 0.85, 0.82, 0.79, 0.76, 0.73, 0.70,
                0.67, 0.64, 0.61, 0.58, 0.55, 0.52, 0.49, 0.46, 0.43, 0.40,
                // 마지막으로 서서히 감소, 간헐적 0
                0.00,
                0.36, 0.33, 0.30, 0.27, 0.24, 0.21, 0.18, 0.15, 0.12, 0.09,
                0.06, 0.03, 0.00, 0.00, 0.00
              ]
        )
    }
}
