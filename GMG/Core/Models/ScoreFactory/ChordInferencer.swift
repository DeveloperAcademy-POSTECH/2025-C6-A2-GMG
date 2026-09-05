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
///
/// Two models run here, and they are only valid as a pair. The chord model was
/// trained on C alone, so it cannot say what key a melody is in and cannot read
/// one it has never seen. `ChordKeyModel` — trained on all twelve — names the
/// key, the melody is rotated so that key becomes C, the chords are read, and
/// their roots are rotated back. The key model's mistakes are therefore part of
/// this class's accuracy, which is why the key is voted on across the whole
/// melody rather than trusted one window at a time.
final class ChordInferencer {
    private let keyModel: ChordKeyModel
    private let chordModel: ChordSlotModel
    private let vocabulary: Vocabulary

    /// Melody rows the graph accepts. Fixed at conversion time, so it is read
    /// from the model rather than assumed.
    private let maxMelodyRows: Int

    /// `<PAD>` in the slot melody vocabulary. A padding row is this in the
    /// pitch column and zero in the other three.
    private let padId: Int = 0

    /// How many chords the UI offers per bar.
    private let candidateCount: Int = 5

    /// Flattens the ranking before a chord is drawn from it. Zero turns drawing
    /// off entirely and takes the ranking as it stands, which is what makes a
    /// run reproducible.
    ///
    /// One means no flattening, and that is the default on purpose: `minP` is
    /// the dial that matters here, and temperature mostly gets in its way.
    /// Below one the leader grows, fewer roots clear the `minP` floor, and the
    /// decoder collapses back to greedy — at `0.9` a steady C major melody gave
    /// the greedy progression outright in 7 runs of 40, against 0 at `1.0`.
    private let temperature: Float
    /// How close to the model's first choice a chord has to be before it counts
    /// as an alternative, as a fraction of that first choice's probability.
    ///
    /// A fixed number of candidates does not work here. The root distribution
    /// is flat — a first choice around `0.3` to `0.45` with the rest of the
    /// mass scattered behind it — so taking a fixed top few would hand the draw
    /// three roots that are noise rather than alternatives, and the root would
    /// come out wrong more often than right. Measuring against the leader
    /// instead makes the decoder greedy wherever the model is decided, and only
    /// opens up where two or three chords are genuinely close.
    ///
    /// Measured on this model at 40 runs of one steady C major melody: `0.6`
    /// gave 13 distinct progressions and never the greedy one, `0.7` gave 8 and
    /// fell back to greedy 10 times, `0.8` barely moved at all. Every setting
    /// tried stayed inside the key — unlike the seq2seq decoder this replaced,
    /// loosening the floor here did not produce chromatic chords, so the floor
    /// is set for variety rather than against drift.
    private let minP: Float
    /// Uniform in `0..<1`. Injected so a test can pin the draw.
    private let random: () -> Float

    init(
        temperature: Float = 1.0,
        minP: Float = 0.6,
        random: @escaping () -> Float = { Float.random(in: 0..<1) }
    ) throws {
        self.temperature = temperature
        self.minP = minP
        self.random = random
        self.keyModel = try ChordKeyModel()
        self.chordModel = try ChordSlotModel()

        guard
            let vocabURL = Bundle.main.url(
                forResource: "TransformerChordInferenceVocab",
                withExtension: "json"
            )
        else { throw ChordInferencerError.notFoundVocab }

        self.vocabulary = try JSONDecoder().decode(
            Vocabulary.self, from: try Data(contentsOf: vocabURL)
        )

        let descriptions = chordModel.model.modelDescription.inputDescriptionsByName
        self.maxMelodyRows = Self.rowCount(of: descriptions["melody"]) ?? 212
    }

    /// The melody length baked into the graph, from its input description.
    ///
    /// The melody input is rank 3 — `(batch, rows, 4)` — and anything else means
    /// the bundled model is not the one this code was written against.
    private static func rowCount(of description: MLFeatureDescription?) -> Int? {
        guard let shape = description?.multiArrayConstraint?.shape, shape.count == 3
        else { return nil }
        return max(1, shape[1].intValue)
    }

    func inference(
        notes: [Note],
        tempo: Tempo = .default
    ) async throws -> ChordInferencerResult {
        let events: [MelodyEvent] = melodyEvents(from: notes, tempo: tempo)
        let windows: [Window] = windows(over: events)
        guard !windows.isEmpty else {
            return ChordInferencerResult(key: Key(root: .C), chordCells: [])
        }

        let key: Int = try await detectKey(over: windows)

        var cells: [ChordCell] = []
        var lastTick: Int = .min
        var sounding: Chord?

        for window in windows {
            // Windows overlap by half so the model always has context on both
            // sides; only what is past the previous window is new.
            for chord in try await predict(window, inKey: key) where chord.tick > lastTick {
                lastTick = chord.tick

                // Every bar carries a chord — the model has no way to say
                // "nothing here" — so a chord that lasts four bars comes back
                // four times. Consecutive bars agreeing is one chord held.
                guard let leading = chord.candidates.first, leading != sounding else {
                    continue
                }
                sounding = leading

                cells.append(
                    ChordCell(
                        chord: leading,
                        chordCandidates: chord.candidates,
                        startTime: tempo.seconds(
                            atTicks: chord.tick,
                            ticksPerQuarter: vocabulary.ticksPerQuarter
                        ),
                        duration: .zero
                    )
                )
            }
        }

        return ChordInferencerResult(
            key: Key(root: NoteName(pitchClass: key)), chordCells: cells
        )
    }
}

// MARK: - The key the rest of the run is read against

extension ChordInferencer {
    /// One key for the whole melody, voted on across its windows.
    ///
    /// Per window the detector is right about 0.895 of the time and per song
    /// 0.956, measured on the training corpus. The app has the whole hummed
    /// melody in hand, so there is no reason to take the weaker number.
    fileprivate func detectKey(over windows: [Window]) async throws -> Int {
        var votes: [Int: Int] = [:]

        for window in windows {
            // The detector reads the melody as it was sung. Rotating first
            // would be circular.
            let melody = melodyRows(
                window.events, startingAt: window.startTick, rotatedBy: 0
            )
            let output = try await keyModel.prediction(
                input: ChordKeyModelInput(melody: melody)
            )

            let logits: [Float] = output.key_logitsShapedArray.scalars
            guard let best = logits.indices.max(by: { logits[$0] < logits[$1] })
            else { continue }
            votes[best, default: 0] += 1
        }

        // A tie goes to the lower pitch class, so the same melody always
        // produces the same key.
        return
            votes.max { left, right in
                left.value == right.value ? left.key > right.key : left.value < right.value
            }?.key ?? 0
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
        let capacity: Int = max(1, maxMelodyRows)

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

    /// One row per note — `[pitch id, duration, bar, offset]` — padded out to
    /// the length the graph was converted at.
    ///
    /// `semitones` is the key the melody is being rotated *out of*, so passing
    /// the detected key puts the melody in C, which is the only key the chord
    /// model was trained on. Passing zero leaves it alone.
    fileprivate func melodyRows(
        _ events: [MelodyEvent],
        startingAt startTick: Int,
        rotatedBy semitones: Int
    ) -> MLMultiArray {
        // A row of zeros is already a padding row: `<PAD>` is id 0, and the
        // other three columns are ignored wherever the pitch column is padding.
        var rows = MLShapedArray<Int32>(
            repeating: Int32(padId), shape: [1, maxMelodyRows, 4]
        )

        let lastBar: Int = max(0, vocabulary.windowBars - 1)

        for (row, event) in events.prefix(maxMelodyRows).enumerated() {
            let position: Int = max(0, event.tick - startTick)
            let pitchClass: Int = ((event.pitchClass - semitones) % 12 + 12) % 12

            rows[scalarAt: [0, row, 0]] = Int32(vocabulary.pitchId(pitchClass))
            rows[scalarAt: [0, row, 1]] = Int32(
                min(vocabulary.maxDuration, max(1, event.duration))
            )
            rows[scalarAt: [0, row, 2]] = Int32(
                min(lastBar, position / vocabulary.ticksPerBar)
            )
            rows[scalarAt: [0, row, 3]] = Int32(position % vocabulary.ticksPerBar)
        }

        return MLMultiArray(rows)
    }
}

// MARK: - Reading the slots

extension ChordInferencer {
    fileprivate struct PredictedChord {
        let tick: Int
        let candidates: [Chord]
    }

    /// One forward pass per window. There is no generation loop: the model
    /// answers for every slot at once.
    ///
    /// The model is read at the grid it was trained on — two slots to a bar —
    /// and the answer is then reduced to one chord per bar. Halving the slot is
    /// what made this model worth having (it took the ceiling against the real
    /// chord track from 0.873 to 0.983), so the grid stays; only what the score
    /// shows is per bar. The two slots' distributions are averaged rather than
    /// one of them being dropped: where both halves agree, that is the chord
    /// either would have given, and where they disagree the bar is decided on
    /// both halves' evidence instead of on the downbeat alone.
    fileprivate func predict(
        _ window: Window,
        inKey key: Int
    ) async throws -> [PredictedChord] {
        let melody = melodyRows(
            window.events, startingAt: window.startTick, rotatedBy: key
        )
        let output = try await chordModel.prediction(
            input: ChordSlotModelInput(melody: melody)
        )

        let rootLogits: MLShapedArray<Float> = output.root_logitsShapedArray
        let typeLogits: MLShapedArray<Float> = output.type_logitsShapedArray

        let slotsPerBar: Int = max(1, vocabulary.ticksPerBar / vocabulary.slotTicks)
        var chords: [PredictedChord] = []

        for firstSlot in stride(from: 0, to: vocabulary.slotsPerWindow, by: slotsPerBar) {
            let slots: Range<Int> =
                firstSlot..<min(
                    firstSlot + slotsPerBar, vocabulary.slotsPerWindow
                )

            // Only the root is drawn. The type is left alone because the model
            // is already sure of it — `0.85` to `0.95` on one quality — so
            // drawing there buys no variety and only risks the occasional chord
            // nobody asked for.
            let rankedRoots = ranking(
                of: averaged(
                    rootLogits,
                    over: slots,
                    classes: vocabulary.rootLabels.count,
                    temperature: temperature
                )
            )
            let rankedTypes = ranking(
                of: averaged(
                    typeLogits, over: slots, classes: vocabulary.typeLabels.count
                )
            )

            guard let chosen = draw(from: rankedRoots, sampling: true) else { continue }

            // What the progression is written against has to lead the candidate
            // list too, or the chord the UI shows is not the one that was chosen.
            let roots: [NoteName] = promoting(chosen.id, in: rankedRoots).map {
                // Back out of C and into the key the melody was actually in.
                NoteName(pitchClass: ($0.id + key) % 12)
            }
            let types: [ChordQuality] = rankedTypes.compactMap {
                vocabulary.typeLabel($0.id).flatMap(ChordQuality.init(label:))
            }

            let candidates: [Chord] = pair(roots, with: types)
            guard !candidates.isEmpty else { continue }

            chords.append(
                PredictedChord(
                    tick: window.startTick + firstSlot * vocabulary.slotTicks,
                    candidates: candidates
                )
            )
        }

        return chords
    }

    /// One head's class probabilities, softmaxed per slot and then averaged
    /// across the slots of a bar.
    ///
    /// Averaging probabilities rather than logits is what makes this a vote:
    /// a slot the model is unsure about spreads its weight and carries less,
    /// while a slot it is certain about dominates the bar.
    ///
    /// Temperature flattens each distribution without reordering it, so it
    /// changes nothing on its own — it only has an effect through `draw`.
    fileprivate func averaged(
        _ logits: MLShapedArray<Float>,
        over slots: Range<Int>,
        classes: Int,
        temperature: Float = 1
    ) -> [Float] {
        guard classes > 0, !slots.isEmpty else { return [] }

        let scale: Float = max(temperature, 0.01)
        var totals: [Float] = Array(repeating: 0, count: classes)

        for slot in slots {
            let slice = logits[0, slot]
            let scores: [Float] = (0..<classes).map { id in
                slice[id].scalar ?? -.greatestFiniteMagnitude
            }

            let highest: Float = scores.max() ?? 0
            let weights: [Float] = scores.map { exp(($0 - highest) / scale) }
            let sum: Float = weights.reduce(0, +)
            guard sum > 0 else { continue }

            for id in 0..<classes {
                totals[id] += weights[id] / sum
            }
        }

        let count = Float(slots.count)
        return totals.map { $0 / count }
    }

    /// Class ids paired with their probabilities, best first.
    fileprivate func ranking(of probabilities: [Float]) -> [(id: Int, probability: Float)] {
        probabilities
            .enumerated()
            .map { (id: $0.offset, probability: $0.element) }
            .sorted { $0.probability > $1.probability }
    }

    /// Picks one class out of the ranking.
    ///
    /// Drawing in proportion to probability is the whole point of temperature:
    /// scaling the logits and then taking the maximum would give back exactly
    /// the same progression every time, because the scaling preserves order.
    fileprivate func draw(
        from ranked: [(id: Int, probability: Float)],
        sampling: Bool
    ) -> (id: Int, probability: Float)? {
        guard sampling, temperature > 0, let leader = ranked.first, ranked.count > 1
        else { return ranked.first }

        // The ranking is sorted, so everything worth drawing from is at the front.
        let floor: Float = minP * leader.probability
        let pool = ranked.prefix { $0.probability >= floor }
        guard pool.count > 1 else { return leader }

        let total: Float = pool.reduce(0) { $0 + $1.probability }
        guard total > 0 else { return leader }

        var cut: Float = min(max(random(), 0), 1) * total
        for entry in pool {
            cut -= entry.probability
            if cut <= 0 { return entry }
        }
        return pool.last
    }

    /// The given class first, the rest left in rank order.
    fileprivate func promoting(
        _ chosen: Int,
        in ranked: [(id: Int, probability: Float)]
    ) -> [(id: Int, probability: Float)] {
        guard let index = ranked.firstIndex(where: { $0.id == chosen }), index != 0
        else { return ranked }

        var reordered = ranked
        reordered.insert(reordered.remove(at: index), at: 0)
        return reordered
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
    let ticksPerBar: Int
    let windowTicks: Int
    let windowBars: Int
    let maxDuration: Int
    let slotTicks: Int
    let slotsPerWindow: Int

    /// What the two heads' class indices mean. Positions are the class ids, so
    /// these lists are the only thing that says a `2` from the root head is a D.
    let rootLabels: [String]
    let typeLabels: [String]

    private let melodyIds: [String: Int]

    private static let unknownId: Int = 3

    enum CodingKeys: String, CodingKey {
        case ticksPerQuarter = "ticks_per_quarter"
        case ticksPerBar = "ticks_per_bar"
        case windowTicks = "window_ticks"
        case windowBars = "window_bars"
        case maxDuration = "max_duration"
        case slotTicks = "slot_ticks"
        case slotsPerWindow = "slots_per_window"
        case slotMelodyTokens = "slot_melody_tokens"
        case rootLabels = "root_labels"
        case typeLabels = "type_labels"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ticksPerQuarter = try container.decode(Int.self, forKey: .ticksPerQuarter)
        ticksPerBar = try container.decode(Int.self, forKey: .ticksPerBar)
        windowTicks = try container.decode(Int.self, forKey: .windowTicks)
        windowBars = try container.decode(Int.self, forKey: .windowBars)
        maxDuration = try container.decode(Int.self, forKey: .maxDuration)
        slotTicks = try container.decode(Int.self, forKey: .slotTicks)
        slotsPerWindow = try container.decode(Int.self, forKey: .slotsPerWindow)
        rootLabels = try container.decode([String].self, forKey: .rootLabels)
        typeLabels = try container.decode([String].self, forKey: .typeLabels)

        let slotMelodyTokens: [String] = try container.decode(
            [String].self, forKey: .slotMelodyTokens)
        melodyIds = Dictionary(
            slotMelodyTokens.enumerated().map { ($1, $0) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    /// The melody vocabulary holds one token per pitch class and nothing else —
    /// duration, bar and offset are numeric columns, not tokens.
    func pitchId(_ pitchClass: Int) -> Int {
        melodyIds["\(ChordToken.pitchPrefix)\(pitchClass)"] ?? Self.unknownId
    }

    func typeLabel(_ id: Int) -> String? {
        typeLabels.indices.contains(id) ? typeLabels[id] : nil
    }
}
