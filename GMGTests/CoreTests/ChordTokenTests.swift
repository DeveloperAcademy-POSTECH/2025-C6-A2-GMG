//  Copyright © 2025 ADA 4th GMG. All rights reserved.

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

    @Test func aSteadyMelodyGetsAConfidentSuggestion() {
        // Quarters and eighths at 120 BPM.
        let beat: Double = 0.5
        let onsets: [Double] = [0, 0.5, 1.0, 1.5, 2.0, 2.25, 2.5, 2.75, 3.0, 3.5]
            .map { $0 * (beat / 0.5) }

        let suggestion = TempoEstimator.suggest(onsets: onsets)

        #expect(suggestion.confidence > TempoEstimator.usableConfidence)
        #expect(suggestion.tempo.phase == 0)
    }

    @Test func onsetsWithNoPulseAreNotWorthShowing() {
        let scattered: [Double] = [0, 0.17, 0.61, 0.68, 1.29, 1.31, 2.02, 2.7, 2.91]
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
}
