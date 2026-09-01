//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

/// A beat grid: how fast, and where the first beat sits.
struct Tempo {
    /// Beats per minute.
    let bpm: Double
    /// Seconds from the start of the recording to beat zero.
    let phase: TimeInterval

    static let `default`: Tempo = .init(bpm: 120, phase: 0)

    var secondsPerBeat: TimeInterval { 60.0 / bpm }

    func ticks(atSeconds seconds: TimeInterval, ticksPerQuarter: Int) -> Int {
        let beats: Double = (seconds - phase) / secondsPerBeat
        return Int((beats * Double(ticksPerQuarter)).rounded())
    }

    func seconds(atTicks ticks: Int, ticksPerQuarter: Int) -> TimeInterval {
        phase + (Double(ticks) / Double(ticksPerQuarter)) * secondsPerBeat
    }

    /// A duration in seconds expressed in ticks, independent of phase.
    func tickLength(ofSeconds seconds: TimeInterval, ticksPerQuarter: Int) -> Int {
        Int(((seconds / secondsPerBeat) * Double(ticksPerQuarter)).rounded())
    }
}

/// A guess at the tempo of a hummed melody, with how much to trust it.
struct TempoSuggestion {
    let tempo: Tempo
    /// Roughly 0 to 1. High means the onsets fell cleanly on simple note
    /// values; low means the singer drifted, or there was no steady pulse.
    let confidence: Double
}

/// Suggests a tempo from note onsets.
///
/// **This is a suggestion for the user to confirm, not a value to feed the
/// model blindly.** Inferring tempo from free humming is a genuinely hard
/// problem and this implementation is not solved:
///
/// - It confuses a tempo with its double often enough to matter. Measured on
///   synthetic melodies of quarters and eighths, it recovers 100, 120 and 132
///   BPM within a beat, but reads 72 as ~142 and 90 as ~134.
/// - Onset jitter of ±30 ms already moves it by a few BPM.
///
/// Until that improves, the reliable sources of tempo are the singer: a tap, a
/// count-in, or a metronome during recording. A count-in in particular makes
/// the tempo exact and removes this problem rather than approximating it.
/// `ChordInferencer` therefore takes a `Tempo` rather than calling this.
enum TempoEstimator {
    /// Below this the suggestion is not worth showing.
    static let usableConfidence: Double = 0.5

    static let searchRange: ClosedRange<Double> = 60...180

    /// Inter-onset intervals in a melody land on simple fractions of the beat.
    /// The weights prefer simpler readings, which is what stops a melody of
    /// eighth notes from being read as sixteenths at half the tempo — snap
    /// distance alone cannot tell those apart, because the finer grid contains
    /// the coarser one exactly.
    private static let noteValues: [(ratio: Double, weight: Double)] = [
        (1.0 / 4, 0.5), (1.0 / 3, 0.5), (1.0 / 2, 0.9), (2.0 / 3, 0.5),
        (3.0 / 4, 0.5), (1.0, 1.0), (3.0 / 2, 0.7), (2.0, 0.9),
        (3.0, 0.6), (4.0, 0.7),
    ]

    private static let bpmStep: Double = 0.5
    private static let tolerance: Double = 0.06

    /// People tap around two beats a second; this leans the search that way
    /// when the intervals alone are ambiguous.
    private static let preferredBeat: TimeInterval = 0.5
    private static let priorWidth: Double = 0.12

    static func suggest(
        onsets: [TimeInterval],
        range: ClosedRange<Double> = searchRange
    ) -> TempoSuggestion {
        let sorted: [TimeInterval] = onsets.sorted()
        guard sorted.count >= 4 else {
            return TempoSuggestion(tempo: .default, confidence: 0)
        }

        var best: (bpm: Double, score: Double) = (120, -1)
        var bpm: Double = range.lowerBound
        while bpm <= range.upperBound {
            let beat: TimeInterval = 60.0 / bpm
            let prior: Double = exp(
                -pow(log(beat / preferredBeat), 2) / (2 * priorWidth * priorWidth)
            )
            let score: Double = intervalScore(sorted, beat: beat) * pow(prior, 0.25)
            if score > best.score {
                best = (bpm, score)
            }
            bpm += bpmStep
        }

        return TempoSuggestion(
            tempo: Tempo(bpm: best.bpm, phase: sorted[0]),
            confidence: max(0, min(1, best.score))
        )
    }

    /// How well the gaps between onsets read as simple note values at this beat.
    private static func intervalScore(_ onsets: [TimeInterval], beat: TimeInterval)
        -> Double
    {
        var total: Double = 0
        var counted: Int = 0

        for (start, end) in zip(onsets, onsets.dropFirst()) {
            let gap: TimeInterval = end - start
            guard gap > 0 else { continue }
            counted += 1

            let ratio: Double = gap / beat
            var bestFit: Double = 0
            for (value, weight) in noteValues {
                let error: Double = abs(ratio - value) / value
                bestFit = max(
                    bestFit, weight * exp(-(error * error) / (2 * tolerance * tolerance))
                )
            }
            total += bestFit
        }

        return counted > 0 ? total / Double(counted) : 0
    }
}
