//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import Testing

@testable import GMG

/// End to end over the bundled model: a melody in, chords out.
///
/// This is the check that the app and the model still agree. The two have
/// drifted apart before without anything failing — a vocabulary the app could
/// not read simply produced no chords — so the assertions here are about the
/// output being usable at all, not about the harmony being right.
struct ChordInferencerTests {

    /// Twelve notes on the beat at 120 BPM, starting at the top of the recording.
    private static func steadyMelody() -> [Note] {
        let names: [NoteName] = [.C, .E, .G, .E, .F, .A, .C, .A, .G, .B, .D, .G]
        return names.enumerated().map { index, name in
            Note(
                name: name,
                octave: 4,
                startTime: Double(index) * 0.5,
                duration: 0.5
            )
        }
    }

    @Test func aMelodyProducesReadableChords() async throws {
        let inferencer = try ChordInferencer()
        let result = try await inferencer.inference(
            notes: Self.steadyMelody(),
            tempo: Tempo(bpm: 120, phase: 0)
        )

        #expect(!result.chordCells.isEmpty, "the model returned no chords at all")

        for cell in result.chordCells {
            #expect(cell.chord != nil, "a chord slot decoded to nothing")
            #expect(!cell.chordCandidates.isEmpty)
            #expect(cell.startTime >= 0)
        }

        // Chords come out in time order and inside the melody, not past its end.
        let times: [TimeInterval] = result.chordCells.map(\.startTime)
        #expect(times == times.sorted())
        #expect(times.allSatisfy { $0 < 60 })
    }

    @Test func chordsLandOnTheBeatGrid() async throws {
        let tempo = Tempo(bpm: 120, phase: 0)
        let result = try await ChordInferencer().inference(
            notes: Self.steadyMelody(), tempo: tempo
        )

        // Every position the model emits is a whole number of ticks, so
        // converting back to seconds must land on the grid to within rounding.
        for cell in result.chordCells {
            let ticks: Int = tempo.ticks(atSeconds: cell.startTime, ticksPerQuarter: 12)
            let snapped: TimeInterval = tempo.seconds(atTicks: ticks, ticksPerQuarter: 12)
            #expect(abs(cell.startTime - snapped) < 0.001)
        }
    }

    @Test func tempoChangesWhereTheChordsLand() async throws {
        let melody = Self.steadyMelody()
        let fast = try await ChordInferencer().inference(
            notes: melody, tempo: Tempo(bpm: 120, phase: 0)
        )
        let slow = try await ChordInferencer().inference(
            notes: melody, tempo: Tempo(bpm: 60, phase: 0)
        )

        // The same recording read at half the tempo is half as many beats, so
        // the model sees a different melody and the chords cannot line up.
        #expect(fast.chordCells.map(\.startTime) != slow.chordCells.map(\.startTime))
    }

    @Test func anEmptyMelodyIsNotAnError() async throws {
        let result = try await ChordInferencer().inference(notes: [])
        #expect(result.chordCells.isEmpty)
    }
}
