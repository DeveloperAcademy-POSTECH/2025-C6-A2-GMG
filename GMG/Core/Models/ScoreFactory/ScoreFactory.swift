//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import AVFoundation
import Combine
import Foundation
import SwiftF0

enum ScoreFactoryError: Error {
    case pitchDetectModelNotFound
    case failedToChordInference
}

enum ScoreFactoryState: Int, CaseIterable, CustomStringConvertible,
    CustomLocalizedStringResourceConvertible
{
    case hummingAnalysis
    case chordGeneration
    case sheetMusicExtraction

    var description: String {
        switch self {
        case .hummingAnalysis: return "Humming analysis in progress."
        case .chordGeneration: return "AI is generating chords."
        case .sheetMusicExtraction: return "Sheet music extraction in progress."
        }
    }

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .hummingAnalysis: return .scoreFactoryState1
        case .chordGeneration: return .scoreFactoryState2
        case .sheetMusicExtraction: return .scoreFactoryState3
        }
    }
}

final class ScoreFactory {
    private(set) var scoreFactoryStatePublisher: CurrentValueSubject<ScoreFactoryState?, Never>

    init() {
        self.scoreFactoryStatePublisher =
            CurrentValueSubject<ScoreFactoryState?, Never>(nil)
    }

    func createScore(
        audioURL: URL
    ) throws -> Score {
        let audioFileName: String = audioURL.lastPathComponent

        if FileManager.default.fileExists(atPath: Score.recordingFolder.path()) == false {
            try FileManager.default.createDirectory(
                at: Score.recordingFolder,
                withIntermediateDirectories: false
            )
        }

        let copiedAudioURL: URL = Score.recordingFolder
            .appending(component: audioFileName)

        try FileManager.default.copyItem(at: audioURL, to: copiedAudioURL)

        scoreFactoryStatePublisher.send(.hummingAnalysis)

        let notes: [Note] = try self.convertAudioToNotes(audioURL: copiedAudioURL)

        scoreFactoryStatePublisher.send(.chordGeneration)

        let inferencer = try ChordInferencer()
        let chordInferencerResult: ChordInferencerResult =
            try inferencer.inference(notes: notes)

        let key: Key = chordInferencerResult.key
        let chordCells: [ChordCell] = chordInferencerResult.chordCells

        scoreFactoryStatePublisher.send(.sheetMusicExtraction)

        let mergedChordCells: [ChordCell] = mergeConsecutiveChordCells(chordCells)

        let file: AVAudioFile = try AVAudioFile(forReading: copiedAudioURL)
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

        let audioLevels: [Float] = try AudioLevelMeter.calculateLevel(from: workingURL)

        return Score(
            title: "Untitled",
            key: key,
            audioURL: copiedAudioURL,
            totalDuration: totalDuration,
            createdAt: Date(),
            updatedAt: Date(),
            notes: notes,
            chordCells: filteredChordCells,
            audioLevels: audioLevels
        )
    }

    private func convertAudioToNotes(audioURL: URL) throws -> [Note] {
        guard
            let modelURL: URL = Bundle.main.url(
                forResource: "SwiftF0",
                withExtension: "onnx"
            )
        else { throw ScoreFactoryError.pitchDetectModelNotFound }

        let pitchDetector: SwiftF0Detector = try SwiftF0Detector(
            modelUrl: modelURL
        )
        let pitchResults: [PitchResult] = try pitchDetector.detect(
            url: audioURL
        )

        let swiftF0Notes: [SwiftF0.Note] = NoteConverter.convert(pitchResults)
        let notes: [Note] = swiftF0Notes.map { note in
            return note.note
        }

        return notes
    }

    private func mergeConsecutiveChordCells(_ chordCells: [ChordCell]) -> [ChordCell] {
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

extension SwiftF0.Note {
    fileprivate var note: Note {
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

        let noteName: NoteName = noteNames[Int(self.pitch) % 12]
        let octave: Int = Int((self.pitch / 12) - 1)
        let startTime: TimeInterval = self.position
        let duration: TimeInterval = self.duration

        let note: Note = Note(
            name: noteName,
            octave: octave,
            startTime: startTime,
            duration: duration
        )

        return note
    }
}
