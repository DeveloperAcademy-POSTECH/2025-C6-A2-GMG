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

/// A tempo recovered from a hummed melody, with how much to trust it.
struct TempoSuggestion {
    let tempo: Tempo
    /// 0 to 1. High means one grid explained the onsets far better than the
    /// alternatives; low means several tempos fit equally well, which is what
    /// happens when there was no steady pulse to find.
    let confidence: Double
}

/// Recovers a beat grid from note onsets.
///
/// The model works in beats — sheet music positions, where tempo never appears
/// — so a recording has to be placed on a beat grid before it can be read. This
/// is the standard three-part recipe from the tempo induction literature:
///
/// 1. **Hypotheses from inter-onset intervals** (Dixon 2001). Intervals between
///    every *pair* of onsets, not just adjacent ones, are clustered; clusters
///    at integer ratios reinforce each other, because a real beat period comes
///    with clusters at its multiples and divisions.
/// 2. **A penalty on rhythmic complexity** (Cemgil, Desain & Kappen 2000).
///    Each onset is scored against the subdivision it lands on, discounted by
///    how deep that subdivision is: on the beat is simpler than the half, which
///    is simpler than the quarter. Without this the search collapses, because
///    halving a tempo turns every eighth into a sixteenth and fits just as
///    well — a finer grid contains the coarser one exactly.
/// 3. **A perceptual prior** (van Noorden & Moelants). Listeners prefer a pulse
///    near 120 BPM; the preference is modelled as a damped resonator with a
///    period of 0.5 s. This breaks the remaining octave ties the way a listener
///    would.
///
/// Measured on synthetic melodies of quarters, eighths, sixteenths, triplets
/// and syncopation, this recovers the tempo within a beat from 80 to 150 BPM,
/// and holds up under ±50 ms of onset jitter. It still reads 72 BPM as 144 —
/// physically the same onsets, and 144 is where the resonance peak sits, so a
/// listener would likely tap there too. That case comes out below
/// `usableConfidence`, so it is reported as unreliable rather than asserted.
///
/// Beat tracking on unaccompanied singing is a hard problem in its own right —
/// no accompaniment to carry the pulse, and soft onsets blurred by portamento
/// and vibrato. Treat a low-confidence result as a prompt to ask the singer,
/// and prefer a count-in during recording, which makes the tempo exact instead
/// of estimated. These thresholds are tuned on synthetic melodies and want
/// checking against real recordings.
enum TempoEstimator {
    /// Below this, ask rather than guess.
    static let usableConfidence: Double = 0.40

    static let searchRange: ClosedRange<Double> = 40...210

    /// Where onsets fall inside a beat, and how complex each position is.
    /// Depth 0 is the beat itself, 1 the half, 2 the quarter and the triplet,
    /// 3 the eighth and the sextuplet.
    private static let subdivisions: [(position: Double, depth: Double)] = [
        (0, 0), (1, 0),
        (1.0 / 2, 1),
        (1.0 / 4, 2), (3.0 / 4, 2), (1.0 / 3, 2), (2.0 / 3, 2),
        (1.0 / 8, 3), (3.0 / 8, 3), (5.0 / 8, 3), (7.0 / 8, 3),
        (1.0 / 6, 3), (5.0 / 6, 3),
    ]

    /// How much each level of subdivision costs. Larger means only simple
    /// rhythms are considered plausible.
    private static let complexityWeight: Double = 0.9

    /// Timing tolerance, in beats. Roughly 36 ms at 100 BPM.
    private static let timingTolerance: Double = 0.06

    /// Rhythm lives between about 50 ms and 2 s (Handel 1989).
    private static let intervalRange: ClosedRange<TimeInterval> = 0.05...2.0
    private static let clusterWidth: TimeInterval = 0.025

    private static let phaseSteps: Int = 24

    static func suggest(onsets: [TimeInterval]) -> TempoSuggestion {
        let sorted: [TimeInterval] = onsets.sorted()
        guard sorted.count >= 4, let first = sorted.first else {
            return TempoSuggestion(tempo: .default, confidence: 0)
        }

        let candidates: [Double] = candidateTempos(sorted)
        guard !candidates.isEmpty else {
            return TempoSuggestion(
                tempo: Tempo(bpm: Tempo.default.bpm, phase: first), confidence: 0
            )
        }

        var best: (bpm: Double, phase: TimeInterval, score: Double) = (120, first, -1)
        var scores: [Double] = []

        for bpm in candidates {
            let beat: TimeInterval = 60.0 / bpm
            var bestHere: Double = -1

            for step in 0..<phaseSteps {
                let phase: TimeInterval =
                    first + beat * Double(step) / Double(phaseSteps) - beat / 2
                let score: Double = fit(sorted, beat: beat, phase: phase) * resonance(beat)

                bestHere = max(bestHere, score)
                if score > best.score {
                    best = (bpm, phase, score)
                }
            }
            scores.append(bestHere)
        }

        // A grid worth trusting stands out from the alternatives. When every
        // tempo explains the onsets about equally well, there was no pulse.
        let median: Double = scores.sorted()[scores.count / 2]
        let confidence: Double =
            best.score > 0 ? max(0, min(1, 1 - median / best.score)) : 0

        return TempoSuggestion(
            tempo: Tempo(bpm: best.bpm, phase: best.phase), confidence: confidence
        )
    }
}

// MARK: - Hypotheses

extension TempoEstimator {
    /// Beat periods worth testing, from clustered inter-onset intervals.
    private static func candidateTempos(_ onsets: [TimeInterval]) -> [Double] {
        var clusters: [(total: TimeInterval, count: Int)] = []

        // Intervals between every pair, not just neighbours: an onset that is
        // off the beat still forms a usable interval with one further away.
        for (index, start) in onsets.enumerated() {
            for end in onsets[(index + 1)...] {
                let interval: TimeInterval = end - start
                guard intervalRange.contains(interval) else { continue }

                var nearest: Int = -1
                var distance: TimeInterval = clusterWidth
                for (position, cluster) in clusters.enumerated() {
                    let gap: TimeInterval = abs(
                        cluster.total / Double(cluster.count) - interval)
                    if gap < distance {
                        distance = gap
                        nearest = position
                    }
                }

                if nearest >= 0 {
                    clusters[nearest].total += interval
                    clusters[nearest].count += 1
                } else {
                    clusters.append((interval, 1))
                }
            }
        }

        let intervals: [(interval: TimeInterval, weight: Double)] = clusters.map {
            ($0.total / Double($0.count), Double($0.count))
        }

        // Clusters at integer ratios support each other; the closer the ratio,
        // the stronger the support.
        var ranked: [(interval: TimeInterval, weight: Double)] = intervals
        for index in ranked.indices {
            for other in intervals where other.interval != ranked[index].interval {
                let low: Double = min(other.interval, ranked[index].interval)
                let high: Double = max(other.interval, ranked[index].interval)
                let ratio: Double = high / low
                let whole: Double = ratio.rounded()

                guard whole >= 2, whole <= 8, abs(ratio - whole) * low < clusterWidth
                else { continue }
                ranked[index].weight += other.weight * (whole <= 4 ? 6 - whole : 1)
            }
        }

        // The beat may be a multiple or a division of any strong interval.
        let multiples: [Double] = [0.25, 1.0 / 3, 0.5, 2.0 / 3, 1, 1.5, 2, 3, 4]
        var tempos: Set<Int> = []
        for cluster in ranked.sorted(by: { $0.weight > $1.weight }).prefix(12) {
            for multiple in multiples {
                let bpm: Double = 60.0 / (cluster.interval * multiple)
                if searchRange.contains(bpm) {
                    tempos.insert(Int((bpm * 2).rounded()))
                }
            }
        }

        return tempos.map { Double($0) / 2 }.sorted()
    }
}

// MARK: - Scoring

extension TempoEstimator {
    /// How well these onsets sit on a grid, favouring simple subdivisions.
    private static func fit(
        _ onsets: [TimeInterval], beat: TimeInterval, phase: TimeInterval
    ) -> Double {
        var total: Double = 0
        for onset in onsets {
            total += score(onset: (onset - phase) / beat)
        }
        return total / Double(onsets.count)
    }

    /// The best a single onset can do: near a subdivision, and a shallow one.
    private static func score(onset positionInBeats: Double) -> Double {
        let fraction: Double = positionInBeats - positionInBeats.rounded(.down)

        var best: Double = 0
        for (position, depth) in subdivisions {
            let error: Double = abs(fraction - position)
            let closeness: Double = exp(-pow(error / timingTolerance, 2) / 2)
            best = max(best, exp(-complexityWeight * depth) * closeness)
        }
        return best
    }

    /// Preference for a pulse near 120 BPM, as a damped resonator.
    private static func resonance(_ beat: TimeInterval) -> Double {
        let preferred: Double = 2.0  // Hz, i.e. a beat every 0.5 s
        let damping: Double = 1.12
        let frequency: Double = 1.0 / beat

        let magnitude: Double =
            1.0
            / sqrt(
                pow(pow(preferred, 2) - pow(frequency, 2), 2) + pow(damping * frequency, 2)
            )
        return sqrt(magnitude)
    }
}
