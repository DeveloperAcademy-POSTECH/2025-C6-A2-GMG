//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import CoreML
import Foundation

struct ChordInferencerResult {
    let key: Key
    let chordCells: [ChordCell]
}

enum ChordInferencerError: Error {
    case notFoundVocab
    case invalidModelOutput
}

/// Runs the chord model over a hummed melody.
///
/// The model works in beats, not seconds: positions are ticks on a grid of
/// `ticksPerQuarter` per quarter note, which is how the training scores were
/// written and why tempo never appears in the model itself. Putting a recording
/// onto that grid needs a tempo, and that is the caller's to supply — from a
/// count-in, a tap, or `TempoEstimator` once the singer has confirmed it.
/// A wrong tempo does not degrade the output gently; it hands the model a
/// melody in the wrong rhythm.
final class ChordInferencer {
    private let model: TransformerChordInference
    private let vocabulary: Vocabulary

    private let maxMelodyLength: Int
    private let maxChordLength: Int

    private let padId: Int = 0
    private let sosId: Int = 1
    private let eosId: Int = 2

    /// How many chords the UI offers per slot.
    private let candidateCount: Int = 5

    init() throws {
        self.model = try TransformerChordInference()

        guard
            let vocabURL = Bundle.main.url(
                forResource: "TransformerChordInferenceVocab",
                withExtension: "json"
            )
        else { throw ChordInferencerError.notFoundVocab }

        self.vocabulary = try JSONDecoder().decode(
            Vocabulary.self, from: try Data(contentsOf: vocabURL)
        )

        let descriptions = model.model.modelDescription.inputDescriptionsByName
        self.maxMelodyLength = Self.length(of: descriptions["melody_tokens"]) ?? 656
        self.maxChordLength = Self.length(of: descriptions["chord_input"]) ?? 171
    }

    private static func length(of description: MLFeatureDescription?) -> Int? {
        guard let shape = description?.multiArrayConstraint?.shape, shape.count == 2
        else { return nil }
        return max(2, shape[1].intValue)
    }

    func inference(
        notes: [Note],
        tempo: Tempo = .default
    ) async throws -> ChordInferencerResult {
        let events: [MelodyEvent] = melodyEvents(from: notes, tempo: tempo)
        guard !events.isEmpty else {
            return ChordInferencerResult(key: Key(root: .C), chordCells: [])
        }

        var key: Key?
        var cells: [ChordCell] = []
        var lastTick: Int = .min

        for window in windows(over: events) {
            let prediction = try await predict(window.events, startingAt: window.startTick)

            if key == nil, let root = prediction.key {
                key = Key(root: root)
            }

            // Windows overlap by half so the model always has context on both
            // sides; only what is past the previous window is new.
            for chord in prediction.chords where chord.tick > lastTick {
                cells.append(
                    ChordCell(
                        chord: chord.candidates.first,
                        chordCandidates: chord.candidates,
                        startTime: tempo.seconds(
                            atTicks: chord.tick,
                            ticksPerQuarter: vocabulary.ticksPerQuarter
                        ),
                        duration: .zero
                    )
                )
                lastTick = chord.tick
            }
        }

        return ChordInferencerResult(key: key ?? Key(root: .C), chordCells: cells)
    }
}

// MARK: - Melody on the tick grid

extension ChordInferencer {
    fileprivate struct MelodyEvent {
        let tick: Int
        let pitchClass: Int
        let duration: Int
    }

    fileprivate struct Window {
        let startTick: Int
        let events: [MelodyEvent]
    }

    fileprivate func melodyEvents(from notes: [Note], tempo: Tempo) -> [MelodyEvent] {
        let perQuarter: Int = vocabulary.ticksPerQuarter

        return
            notes
            .map { note in
                MelodyEvent(
                    tick: tempo.ticks(atSeconds: note.startTime, ticksPerQuarter: perQuarter),
                    pitchClass: note.name.pitchClass,
                    duration: min(
                        vocabulary.maxDuration,
                        max(
                            1,
                            tempo.tickLength(
                                ofSeconds: note.duration, ticksPerQuarter: perQuarter
                            )
                        )
                    )
                )
            }
            .filter { $0.tick >= 0 }
            .sorted { $0.tick < $1.tick }
    }

    /// Slices the melody the way training did: a fixed span of bars, hopping by
    /// half of it, and cut short if it would overrun the model's input length.
    fileprivate func windows(over events: [MelodyEvent]) -> [Window] {
        let span: Int = vocabulary.windowTicks
        let hop: Int = max(1, span / 2)
        let capacity: Int = max(1, (maxMelodyLength - 2) / 3)

        guard let end = events.last?.tick else { return [] }

        var windows: [Window] = []
        var start: Int = 0

        while start <= end {
            var slice: [MelodyEvent] = events.filter {
                $0.tick >= start && $0.tick < start + span
            }
            if slice.count > capacity {
                slice = Array(slice.prefix(capacity))
            }
            if !slice.isEmpty {
                windows.append(Window(startTick: start, events: slice))
            }
            start += hop
        }

        return windows
    }

    fileprivate func melodyTokenIds(_ events: [MelodyEvent], startTick: Int) -> [Int] {
        var ids: [Int] = [sosId]
        var previous: Int = 0

        for event in events {
            let position: Int = event.tick - startTick
            let delta: Int = min(vocabulary.maxTimeShift, max(0, position - previous))
            previous = position

            ids.append(vocabulary.melodyId("\(ChordToken.timeShiftPrefix)\(delta)"))
            ids.append(vocabulary.melodyId("\(ChordToken.pitchPrefix)\(event.pitchClass)"))
            ids.append(vocabulary.melodyId("\(ChordToken.durationPrefix)\(event.duration)"))
        }
        ids.append(eosId)

        if ids.count < maxMelodyLength {
            ids += Array(repeating: padId, count: maxMelodyLength - ids.count)
        }
        return Array(ids.prefix(maxMelodyLength))
    }
}

// MARK: - Constrained decoding

extension ChordInferencer {
    /// Chord tokens follow a fixed cycle: `<SOS> Key (TimeShift Root Type)* <EOS>`.
    /// Holding each step to the slot it is in stops a shaky model from emitting
    /// a sequence that cannot be read back as chords at all.
    enum Slot {
        case key
        case timeShift
        case root
        case type

        static func at(position: Int) -> Slot {
            guard position > 1 else { return .key }
            switch (position - 2) % 3 {
            case 0: return .timeShift
            case 1: return .root
            default: return .type
            }
        }
    }

    fileprivate struct PredictedChord {
        let tick: Int
        let candidates: [Chord]
    }

    fileprivate struct Prediction {
        let key: NoteName?
        let chords: [PredictedChord]
    }

    fileprivate func predict(
        _ events: [MelodyEvent],
        startingAt startTick: Int
    ) async throws -> Prediction {
        let melodyTokens = MLMultiArray(
            MLShapedArray<Int32>(
                scalars: melodyTokenIds(events, startTick: startTick).map(Int32.init),
                shape: [1, maxMelodyLength]
            )
        )

        var chordArray = MLShapedArray<Int32>(
            repeating: Int32(padId), shape: [1, maxChordLength]
        )
        chordArray[scalarAt: [0, 0]] = Int32(sosId)

        var key: NoteName?
        var chords: [PredictedChord] = []
        var tick: Int = startTick
        var roots: [NoteName] = []

        for position in 1..<maxChordLength {
            let output = try await model.prediction(
                input: TransformerChordInferenceInput(
                    melody_tokens: melodyTokens,
                    chord_input: MLMultiArray(chordArray)
                )
            )

            let slot: Slot = Slot.at(position: position)
            let ranked = rank(
                output.chord_outputShapedArray,
                at: position - 1,
                allowing: vocabulary.ids(for: slot),
                endingAllowed: slot == .timeShift
            )

            guard let best = ranked.first, best.id != eosId else { break }
            chordArray[scalarAt: [0, position]] = Int32(best.id)

            switch slot {
            case .key:
                key = vocabulary.chordToken(best.id).flatMap(NoteName.init(token:))

            case .timeShift:
                tick += vocabulary.timeShift(best.id) ?? 0

            case .root:
                roots = ranked.compactMap {
                    vocabulary.chordToken($0.id).flatMap(NoteName.init(token:))
                }

            case .type:
                let types: [ChordQuality] = ranked.compactMap {
                    vocabulary.chordToken($0.id).flatMap(ChordQuality.init(token:))
                }
                let candidates: [Chord] = pair(roots, with: types)
                if !candidates.isEmpty {
                    chords.append(PredictedChord(tick: tick, candidates: candidates))
                }
                roots = []
            }
        }

        return Prediction(key: key, chords: chords)
    }

    /// Softmax over the tokens this slot allows, best first.
    fileprivate func rank(
        _ logits: MLShapedArray<Float>,
        at position: Int,
        allowing allowed: [Int],
        endingAllowed: Bool
    ) -> [(id: Int, probability: Float)] {
        var ids: [Int] = allowed
        if endingAllowed {
            ids.append(eosId)
        }
        guard !ids.isEmpty else { return [] }

        let slice = logits[0, position]
        let scores: [(id: Int, logit: Float)] = ids.map { id in
            (id, slice[id].scalar ?? -.greatestFiniteMagnitude)
        }

        let highest: Float = scores.map(\.logit).max() ?? 0
        let weights: [Float] = scores.map { exp($0.logit - highest) }
        let total: Float = weights.reduce(0, +)
        guard total > 0 else {
            return scores.sorted { $0.logit > $1.logit }.map { ($0.id, 0) }
        }

        return zip(scores, weights)
            .map { (id: $0.0.id, probability: $0.1 / total) }
            .sorted { $0.probability > $1.probability }
    }

    /// Roots crossed with types, best-first on both, cut to what the UI shows.
    fileprivate func pair(_ roots: [NoteName], with types: [ChordQuality]) -> [Chord] {
        guard !roots.isEmpty, !types.isEmpty else { return [] }

        var chords: [Chord] = []
        // Walk the cross product by increasing combined rank, which is the same
        // order a product of the two probabilities would give for lists that
        // are already sorted.
        for total in 0..<(roots.count + types.count - 1) {
            for rootRank in 0...total {
                let typeRank: Int = total - rootRank
                guard rootRank < roots.count, typeRank < types.count else { continue }
                chords.append(Chord(root: roots[rootRank], quality: types[typeRank]))
            }
        }
        return Array(chords.prefix(candidateCount))
    }
}

// MARK: - Vocabulary

/// The token list plus the grid it was built for.
///
/// The grid values are read from the file rather than hardcoded, so
/// regenerating the vocabulary on the Python side cannot leave the app
/// clamping to bounds that no longer exist.
private struct Vocabulary: Decodable {
    let ticksPerQuarter: Int
    let windowTicks: Int
    let maxTimeShift: Int
    let maxDuration: Int

    private let chordTokens: [String]
    private let melodyIds: [String: Int]
    private let timeShifts: [Int: Int]
    private let slots: [String: [Int]]

    private static let unknownId: Int = 3

    enum CodingKeys: String, CodingKey {
        case ticksPerQuarter = "ticks_per_quarter"
        case windowTicks = "window_ticks"
        case maxTimeShift = "max_time_shift"
        case maxDuration = "max_duration"
        case melodyTokens = "melody_tokens"
        case chordTokens = "chord_tokens"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ticksPerQuarter = try container.decode(Int.self, forKey: .ticksPerQuarter)
        windowTicks = try container.decode(Int.self, forKey: .windowTicks)
        maxTimeShift = try container.decode(Int.self, forKey: .maxTimeShift)
        maxDuration = try container.decode(Int.self, forKey: .maxDuration)

        let melodyTokens: [String] = try container.decode(
            [String].self, forKey: .melodyTokens)
        chordTokens = try container.decode([String].self, forKey: .chordTokens)

        melodyIds = Dictionary(
            melodyTokens.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first }
        )

        var shifts: [Int: Int] = [:]
        var found: [String: [Int]] = [:]
        let prefixes: [String] = [
            ChordToken.keyPrefix, ChordToken.timeShiftPrefix,
            ChordToken.rootPrefix, ChordToken.typePrefix,
        ]

        for (id, token) in chordTokens.enumerated() {
            for prefix in prefixes where token.hasPrefix(prefix) {
                found[prefix, default: []].append(id)
                if prefix == ChordToken.timeShiftPrefix {
                    shifts[id] = Int(token.dropFirst(prefix.count)) ?? 0
                }
            }
        }
        timeShifts = shifts
        slots = found
    }

    func melodyId(_ token: String) -> Int { melodyIds[token] ?? Self.unknownId }

    func chordToken(_ id: Int) -> String? {
        chordTokens.indices.contains(id) ? chordTokens[id] : nil
    }

    func timeShift(_ id: Int) -> Int? { timeShifts[id] }

    fileprivate func ids(for slot: ChordInferencer.Slot) -> [Int] {
        switch slot {
        case .key: return slots[ChordToken.keyPrefix] ?? []
        case .timeShift: return slots[ChordToken.timeShiftPrefix] ?? []
        case .root: return slots[ChordToken.rootPrefix] ?? []
        case .type: return slots[ChordToken.typePrefix] ?? []
        }
    }
}
