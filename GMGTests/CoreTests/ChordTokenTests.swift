//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import Testing

@testable import GMG

/// The app and the model have to spell chords the same way.
///
/// They did not, for a long time: the vocabulary emitted `Type_maj` while the
/// app looked for `Type_M`. Nothing errored — unknown names decode to `nil`, so
/// plain major chords, the most common chord in the training data, were dropped
/// on the way to the screen. These tests exist so that cannot come back quietly.
struct ChordTokenTests {

    /// Must match the right-hand side of `chord_inference.musicxml.KIND_TO_TYPE`.
    private static let vocabularyTypeNames: [String] = [
        "maj", "m", "7", "m7", "maj7", "m7b5", "dim", "dim7", "9", "sus4", "aug",
    ]

    @Test func everyVocabularyTypeDecodes() {
        for name in Self.vocabularyTypeNames {
            #expect(
                ChordQuality(token: "Type_\(name)") != nil,
                "Type_\(name) is in the model's vocabulary but the app cannot read it"
            )
        }
    }

    @Test func plainMajorDecodes() {
        // The regression itself.
        #expect(ChordQuality(token: "Type_maj") == .maj)
        #expect(ChordQuality(token: "Type_maj7") == .maj7)
        #expect(ChordQuality(token: "Type_m7b5") == .halfDim7)
        #expect(ChordQuality(token: "Type_dim7") == .dim7)
    }

    @Test func qualityTokensRoundTrip() {
        for quality in ChordQuality.allCases {
            #expect(ChordQuality(token: "Type_\(quality.tokenName)") == quality)
        }
    }

    @Test func unknownQualityIsRejectedRatherThanGuessed() {
        #expect(ChordQuality(token: "Type_M") == nil)
        #expect(ChordQuality(token: "Type_wat") == nil)
        #expect(ChordQuality(token: "maj") == nil)
    }

    @Test func rootTokensRoundTrip() {
        for pitchClass in 0..<12 {
            let name = NoteName(pitchClass: pitchClass)
            #expect(NoteName(token: "Root_\(name.tokenName)") == name)
            #expect(name.pitchClass == pitchClass)
        }
    }

    @Test func keyTokensReadTheSameNames() {
        #expect(NoteName(token: "Key_C") == .C)
        #expect(NoteName(token: "Key_F#") == .Fs)
    }

    @Test func flatSpellingsShareAPitchClassWithTheirSharp() {
        #expect(NoteName.Db.pitchClass == NoteName.Cs.pitchClass)
        #expect(NoteName.Bb.pitchClass == NoteName.As.pitchClass)
        // Tokens are always the sharp spelling, so a flat still encodes.
        #expect(NoteName.Bb.tokenName == "A#")
    }

    @Test func slotsFollowTheChordCycle() {
        // <SOS> Key (TimeShift Root Type)* — index 0 is the start token.
        #expect(ChordInferencer.Slot.at(position: 1) == .key)
        #expect(ChordInferencer.Slot.at(position: 2) == .timeShift)
        #expect(ChordInferencer.Slot.at(position: 3) == .root)
        #expect(ChordInferencer.Slot.at(position: 4) == .type)
        #expect(ChordInferencer.Slot.at(position: 5) == .timeShift)
        #expect(ChordInferencer.Slot.at(position: 6) == .root)
        #expect(ChordInferencer.Slot.at(position: 7) == .type)
    }
}

/// The tick grid is the model's unit of time; seconds only exist at the edges.
struct TempoTests {

    @Test func ticksAndSecondsAreInverses() {
        let tempo = Tempo(bpm: 120, phase: 1.5)

        // 120 BPM is half a second a beat, so a bar of 4/4 is 48 ticks and 2 s.
        #expect(tempo.ticks(atSeconds: 1.5, ticksPerQuarter: 12) == 0)
        #expect(tempo.ticks(atSeconds: 2.0, ticksPerQuarter: 12) == 12)
        #expect(tempo.ticks(atSeconds: 3.5, ticksPerQuarter: 12) == 48)

        #expect(tempo.seconds(atTicks: 0, ticksPerQuarter: 12) == 1.5)
        #expect(tempo.seconds(atTicks: 48, ticksPerQuarter: 12) == 3.5)
    }

    @Test func durationsIgnorePhase() {
        let tempo = Tempo(bpm: 120, phase: 7.25)
        // An eighth note at 120 BPM is 250 ms, which is 6 ticks.
        #expect(tempo.tickLength(ofSeconds: 0.25, ticksPerQuarter: 12) == 6)
        #expect(tempo.tickLength(ofSeconds: 2.0, ticksPerQuarter: 12) == 48)
    }

    /// Onsets for a melody at `bpm`, given positions in twelfths of a beat.
    private func onsets(bpm: Double, twelfths: [Int], startingAt origin: Double = 3)
        -> [TimeInterval]
    {
        let tick: Double = (60.0 / bpm) / 12.0
        return twelfths.map { Double($0) * tick + origin }
    }

    /// Four bars of quarters and eighths.
    private static let quartersAndEighths: [Int] = [
        0, 12, 24, 36, 48, 54, 60, 66, 72, 84, 96, 108, 120, 126, 132, 144,
    ]

    @Test(arguments: [80.0, 90.0, 100.0, 110.0, 120.0, 132.0, 150.0])
    func recoversTheTempoOfASteadyMelody(bpm: Double) {
        let suggestion = TempoEstimator.suggest(
            onsets: onsets(bpm: bpm, twelfths: Self.quartersAndEighths)
        )

        #expect(abs(suggestion.tempo.bpm - bpm) < 2)
        #expect(suggestion.confidence > TempoEstimator.usableConfidence)
    }

    /// Halving a tempo turns every eighth into a sixteenth and fits the grid
    /// exactly as well, so snap distance alone collapses to the slowest tempo
    /// in range. The complexity penalty is what stops that.
    @Test func doesNotCollapseToHalfTempo() {
        let suggestion = TempoEstimator.suggest(
            onsets: onsets(bpm: 120, twelfths: Self.quartersAndEighths)
        )
        #expect(suggestion.tempo.bpm > 100)
    }

    @Test func handlesTripletsAndSyncopation() {
        let triplets = TempoEstimator.suggest(
            onsets: onsets(
                bpm: 120,
                twelfths: [0, 4, 8, 12, 16, 20, 24, 36, 48, 52, 56, 60, 72, 84, 96, 108]
            )
        )
        #expect(abs(triplets.tempo.bpm - 120) < 2)

        let syncopated = TempoEstimator.suggest(
            onsets: onsets(
                bpm: 110, twelfths: [0, 6, 18, 24, 30, 42, 48, 54, 66, 72, 78, 90, 96]
            )
        )
        #expect(abs(syncopated.tempo.bpm - 110) < 2)
    }

    @Test func survivesHummingJitter() {
        var state: UInt64 = 7
        func wobble() -> Double {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double(Int64(bitPattern: state >> 11)) / Double(1 << 52) - 1.0
        }

        // ±30 ms is a realistic spread for a sung onset.
        let jittered: [TimeInterval] = onsets(
            bpm: 100, twelfths: Self.quartersAndEighths
        ).map { $0 + wobble() * 0.03 }

        let suggestion = TempoEstimator.suggest(onsets: jittered)
        #expect(abs(suggestion.tempo.bpm - 100) < 2)
        #expect(suggestion.confidence > TempoEstimator.usableConfidence)
    }

    @Test func onsetsWithNoPulseAreNotWorthShowing() {
        let scattered: [Double] = [
            0, 0.17, 0.61, 0.68, 1.29, 1.31, 2.02, 2.7, 2.91, 3.44, 3.61, 4.2,
        ]
        #expect(
            TempoEstimator.suggest(onsets: scattered).confidence
                < TempoEstimator.usableConfidence
        )
    }

    @Test func tooFewOnsetsFallBackWithoutPretending() {
        let suggestion = TempoEstimator.suggest(onsets: [0, 0.5])
        #expect(suggestion.confidence == 0)
        #expect(suggestion.tempo.bpm == Tempo.default.bpm)
    }

    /// The phase places beat zero so the melody's own onsets land on the grid.
    @Test func phaseAlignsTheGridToTheMelody() {
        let suggestion = TempoEstimator.suggest(
            onsets: onsets(bpm: 120, twelfths: Self.quartersAndEighths, startingAt: 3)
        )

        let beats: Double = (3.0 - suggestion.tempo.phase) / suggestion.tempo.secondsPerBeat
        #expect(abs(beats - beats.rounded()) < 0.1)
    }
}
