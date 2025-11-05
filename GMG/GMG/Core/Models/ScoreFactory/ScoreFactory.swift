//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import AVFoundation
import Combine
import Foundation
import SwiftF0

enum ScoreFactoryError: Error {
    case pitchDetectModelNotFound
    case failedToChordInference
}

enum ScoreFactoryState: Int {
    case hummingAnalysis
    case chordGeneration
    case sheetMusicExtraction
}

final class ScoreFactory {
    private(set) var scoreFactoryStatePublisher:
        CurrentValueSubject<ScoreFactoryState?, Never>

    init() {
        self.scoreFactoryStatePublisher =
            CurrentValueSubject<ScoreFactoryState?, Never>(nil)
    }

    func createScore(
        audioUrl: URL
    ) throws -> Score {
        Logger.debug("Main Thread: \(Thread.isMainThread)")

        scoreFactoryStatePublisher.send(.hummingAnalysis)

        let notes: [Note] = try self.convertAudioToNotes(audioUrl: audioUrl)

        scoreFactoryStatePublisher.send(.chordGeneration)

        let inferencer = try ChordInferencer()
        let chordInferencerResult: ChordInferencerResult =
            try inferencer.inference(notes: notes)

        let key: Key = chordInferencerResult.key
        let chordCells: [ChordCell] = chordInferencerResult.chordCells

        scoreFactoryStatePublisher.send(.sheetMusicExtraction)

        let mergedChordCells: [ChordCell] = mergeChordCells(chordCells)

        let file: AVAudioFile = try AVAudioFile(forReading: audioUrl)
        let totalDuration: TimeInterval =
            TimeInterval(file.length) / file.fileFormat.sampleRate

        var filteredChordCells: [ChordCell] = mergedChordCells.filter {
            chordCell in
            chordCell.startTime <= totalDuration
        }

        /// 첫 번째 코드를 0초에 재생되도록 변경
        if let firstChordCell: ChordCell = filteredChordCells.first,
            firstChordCell.startTime > TimeInterval.zero
        {
            let newChordCell: ChordCell = ChordCell(
                chord: firstChordCell.chord,
                chordCandidates: firstChordCell.chordCandidates,
                startTime: .zero
            )
            filteredChordCells = [newChordCell] + filteredChordCells[1...]
        }

        return Score(
            title: "Untitled",
            key: key,
            audioUrl: audioUrl,
            totalDuration: totalDuration,
            createdAt: Date(),
            updatedAt: Date(),
            notes: notes,
            chordCells: filteredChordCells
        )
    }

    private func convertAudioToNotes(audioUrl: URL) throws -> [Note] {
        guard
            let modelUrl: URL = Bundle.main.url(
                forResource: "SwiftF0",
                withExtension: "onnx"
            )
        else { throw ScoreFactoryError.pitchDetectModelNotFound }

        let pitchDetector: SwiftF0Detector = try SwiftF0Detector(
            modelUrl: modelUrl
        )
        let pitchResults: [PitchResult] = try pitchDetector.detect(
            url: audioUrl
        )

        let swiftF0Notes: [SwiftF0.Note] = NoteConverter.convert(pitchResults)
        let notes: [Note] = swiftF0Notes.map { note in
            return convertSwiftF0NoteToNote(note)
        }

        return notes
    }

    private func convertSwiftF0NoteToNote(_ swiftF0Note: SwiftF0.Note) -> Note {
        let noteNames: [NoteName] = [
            .C,
            .Cs,
            .D,
            .Ds,
            .E,
            .F,
            .Fs,
            .G,
            .Gs,
            .A,
            .As,
            .B,
        ]

        let noteName: NoteName = noteNames[Int(swiftF0Note.pitch) % 12]
        let octave: Int = Int((swiftF0Note.pitch / 12) - 1)
        let startTime: TimeInterval = swiftF0Note.position
        let duration: TimeInterval = swiftF0Note.duration

        let note: Note = Note(
            name: noteName,
            octave: octave,
            startTime: startTime,
            duration: duration
        )

        return note
    }

    private func mergeChordCells(_ chordCells: [ChordCell]) -> [ChordCell] {
        var mergedChordCells: [ChordCell] = []

        for chordCell in chordCells {
            if let lastMergedChordCell = mergedChordCells.last,
                lastMergedChordCell.chord == chordCell.chord
            {
                continue
            } else {
                mergedChordCells.append(chordCell)
            }
        }

        return mergedChordCells
    }
}
