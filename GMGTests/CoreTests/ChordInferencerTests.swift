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
        let inferencer = try ChordInferencer(temperature: 0)
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
        let result = try await ChordInferencer(temperature: 0).inference(
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

    /// The score carries one chord per bar, so every chord starts on a bar line
    /// — 48 ticks at 12 per quarter. The model is still read at two slots to a
    /// bar; a chord landing on a half-bar means the two were not folded.
    @Test func chordsLandOnBarLines() async throws {
        let tempo = Tempo(bpm: 120, phase: 0)
        let result = try await ChordInferencer(temperature: 0).inference(
            notes: Self.steadyMelody(), tempo: tempo
        )

        #expect(!result.chordCells.isEmpty)
        for cell in result.chordCells {
            let ticks: Int = tempo.ticks(atSeconds: cell.startTime, ticksPerQuarter: 12)
            #expect(
                ticks % 48 == 0,
                "a chord landed at tick \(ticks), which is not a bar line"
            )
        }
    }

    /// No bar may carry two chords: one bar, one cell.
    @Test func everyBarHoldsAtMostOneChord() async throws {
        let tempo = Tempo(bpm: 120, phase: 0)
        let result = try await ChordInferencer(temperature: 0).inference(
            notes: Self.steadyMelody(), tempo: tempo
        )

        let bars: [Int] = result.chordCells.map {
            tempo.ticks(atSeconds: $0.startTime, ticksPerQuarter: 12) / 48
        }
        #expect(bars == Array(Set(bars)).sorted(), "a bar carries more than one chord")
    }

    /// The model answers for every bar of a window whether the chord changed
    /// or not, so a chord held for four bars comes back four times. Without
    /// folding those the UI would show the same chord four times in a row.
    @Test func aHeldChordIsOneCellRatherThanOnePerBar() async throws {
        let result = try await ChordInferencer(temperature: 0).inference(
            notes: Self.steadyMelody(), tempo: Tempo(bpm: 120, phase: 0)
        )

        #expect(!result.chordCells.isEmpty)
        for (previous, next) in zip(result.chordCells, result.chordCells.dropFirst()) {
            #expect(
                previous.chord != next.chord,
                "\(String(describing: previous.chord)) repeats in adjacent cells"
            )
        }
    }

    /// The melody is rotated into C before the chord model sees it, and the
    /// roots are rotated back afterwards. Getting either sign wrong leaves a
    /// melody in C working perfectly — the rotation is the identity there — so
    /// this is the test that has to be in a key that is not C.
    @Test func thesameMelodyInAnotherKeyGivesTheSameProgressionTransposed()
        async throws
    {
        let tempo = Tempo(bpm: 120, phase: 0)
        let inC = Self.steadyMelody()
        let inF = inC.map {
            Note(
                name: NoteName(pitchClass: $0.name.pitchClass + 5),
                octave: $0.octave,
                startTime: $0.startTime,
                duration: $0.duration
            )
        }

        let fromC = try await ChordInferencer(temperature: 0).inference(
            notes: inC, tempo: tempo
        )
        let fromF = try await ChordInferencer(temperature: 0).inference(
            notes: inF, tempo: tempo
        )

        #expect(fromC.key.root.pitchClass == 0)
        #expect(fromF.key.root.pitchClass == 5)

        // Both melodies reach the chord model as the same rotated input, so the
        // progressions must differ by exactly the five semitones between them.
        #expect(fromC.chordCells.count == fromF.chordCells.count)
        for (c, f) in zip(fromC.chordCells, fromF.chordCells) {
            #expect(c.chord?.quality == f.chord?.quality)
            #expect(
                f.chord?.root.pitchClass
                    == c.chord.map { ($0.root.pitchClass + 5) % 12 },
                "\(String(describing: c.chord)) should transpose to \(String(describing: f.chord))"
            )
        }
    }

    @Test func tempoChangesWhereTheChordsLand() async throws {
        let melody = Self.steadyMelody()
        // Sampling off, so the two runs can only differ because of the tempo.
        let fast = try await ChordInferencer(temperature: 0).inference(
            notes: melody, tempo: Tempo(bpm: 120, phase: 0)
        )
        let slow = try await ChordInferencer(temperature: 0).inference(
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

    /// The same melody twice at temperature zero, to prove the decoder itself
    /// adds nothing — without this, the sampling test below could pass on a
    /// model that was never stable to begin with.
    @Test func withoutTemperatureTheSameMelodyRepeats() async throws {
        let melody = Self.steadyMelody()
        let tempo = Tempo(bpm: 120, phase: 0)

        let first = try await ChordInferencer(temperature: 0).inference(
            notes: melody, tempo: tempo
        )
        let second = try await ChordInferencer(temperature: 0).inference(
            notes: melody, tempo: tempo
        )

        #expect(first.chordCells.map(\.chord) == second.chordCells.map(\.chord))
    }

    /// Temperature has to reach the chords, not just the probabilities.
    ///
    /// Two runs drawing from opposite ends of the ranking: one always takes the
    /// front of the pool, the other always the back. If scaling the logits were
    /// the only change, both would still be the model's first choice and these
    /// would come out identical.
    @Test func temperatureChangesWhichChordsAreDrawn() async throws {
        let melody = Self.steadyMelody()
        let tempo = Tempo(bpm: 120, phase: 0)

        let likeliest = try await ChordInferencer(
            temperature: 1, minP: 0.5, random: { 0 }
        ).inference(notes: melody, tempo: tempo)

        let unlikeliest = try await ChordInferencer(
            temperature: 1, minP: 0.5, random: { 0.999 }
        ).inference(notes: melody, tempo: tempo)

        #expect(!likeliest.chordCells.isEmpty)
        #expect(!unlikeliest.chordCells.isEmpty)
        #expect(likeliest.chordCells.map(\.chord) != unlikeliest.chordCells.map(\.chord))
    }

    /// The chord shown is the chord the model went on to write against.
    @Test func theLeadCandidateIsTheChordThatWasChosen() async throws {
        let result = try await ChordInferencer(
            temperature: 1, minP: 0.5, random: { 0.999 }
        ).inference(notes: Self.steadyMelody(), tempo: Tempo(bpm: 120, phase: 0))

        for cell in result.chordCells {
            #expect(cell.chord == cell.chordCandidates.first)
        }
    }
}
