//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import CoreML

struct ChordInferencerResult {
    let key: Key
    let chordCells: [ChordCell]
}

enum ChordInferencerError: Error {
    case notFoundVocab
    case invalidModelOutput
}

final class ChordInferencer {
    private let model: TransformerChordInference
    private let vocab: Vocab

    private var maxMelodyLength: Int = 656
    private var maxChordLength: Int = 171

    private let padId: Int = 0
    private let sosId: Int = 1
    private let eosId: Int = 2
    private let unkId: Int = 3

    init() throws {
        self.model = try TransformerChordInference()

        if let melodyDescription: MLMultiArrayConstraint = model.model
            .modelDescription
            .inputDescriptionsByName["melody_tokens"]?.multiArrayConstraint,
            melodyDescription.shape.count == 2
        {
            let length: Int = melodyDescription.shape[1].intValue
            self.maxMelodyLength = max(1, length)
        }

        if let chordDescription: MLMultiArrayConstraint = model.model
            .modelDescription
            .inputDescriptionsByName["chord_input"]?.multiArrayConstraint,
            chordDescription.shape.count == 2
        {
            let length: Int = chordDescription.shape[1].intValue
            self.maxChordLength = max(2, length)
        }

        guard
            let vocabURL =
                Bundle.main.url(
                    forResource: "TransformerChordInferenceVocab",
                    withExtension: "json"
                )
        else { throw ChordInferencerError.notFoundVocab }

        let vocabData = try Data(contentsOf: vocabURL)

        self.vocab = try JSONDecoder().decode(Vocab.self, from: vocabData)
    }

    func inference(notes: [Note]) async throws -> ChordInferencerResult {
        guard !notes.isEmpty else {
            return ChordInferencerResult(key: Key(root: .C), chordCells: [])
        }

        var key: Key? = nil
        var previousResults: [[InferenceResult]] = []
        var chordCells: [ChordCell] = []

        var startIndex: Int = 0
        var startTime: TimeInterval = notes[0].startTime
        var endIndex: Int = 0
        var endTime: TimeInterval = 0

        while startIndex < notes.endIndex {
            let windowLimitTime: TimeInterval = startTime + 51.2
            endIndex =
                notes.firstIndex { $0.startTime >= windowLimitTime }
                ?? notes.endIndex

            let maxNotesPerSlice = (maxMelodyLength - 2) / 3
            if (endIndex - startIndex) > maxNotesPerSlice {
                endIndex = startIndex + maxNotesPerSlice
            }

            if startIndex >= endIndex { break }

            var currentPosition: Int = 0
            let slicedTokens: [String] = notes[startIndex..<endIndex]
                .map { note in
                    Note(
                        name: note.name,
                        octave: note.octave,
                        startTime: note.startTime - startTime,
                        duration: note.duration
                    )
                }
                .sorted { $0.startTime < $1.startTime }
                .flatMap { note -> [String] in
                    let notePosition = max(
                        0,
                        min(511, Int((note.startTime * 10.0).rounded()))
                    )
                    let delta = notePosition - currentPosition
                    currentPosition = notePosition
                    return note.tokens(delta: delta)
                }

            let inferenceResults: [[InferenceResult]] = try await inference(
                tokens: slicedTokens,
                previousResults: previousResults
            )

            if key == nil,
                let keyTokenId = inferenceResults.first?.first?.id,
                let keyToken = vocab.chordToken(id: keyTokenId),
                let root = NoteName(token: keyToken)
            {
                key = Key(root: root)
            }

            let slicedChordCells: [ChordCell] = convertToChordCells(
                inferenceResults
            )
            .map { chordCell in
                ChordCell(
                    chord: chordCell.chord,
                    chordCandidates: chordCell.chordCandidates,
                    startTime: startTime + chordCell.startTime,
                    duration: .zero
                )
            }
            .filter { $0.startTime >= endTime }

            if !slicedChordCells.isEmpty {
                chordCells.append(contentsOf: slicedChordCells)
            }

            let sliceLength = endIndex - startIndex
            let advance = max(1, (sliceLength * 2) / 3)
            startIndex += advance
            if startIndex >= notes.endIndex { break }
            startTime = notes[startIndex].startTime

            if endIndex > 0 {
                endTime = max(
                    notes[endIndex - 1].startTime,
                    chordCells.last?.startTime ?? endTime
                )
            }

            var prevChordPosition: Int = 0
            previousResults = slicedChordCells.flatMap { chordCell in
                let chordPosition = max(
                    0,
                    min(511, Int(((chordCell.startTime - startTime) * 10.0).rounded()))
                )
                let delta = chordPosition - prevChordPosition
                prevChordPosition = chordPosition

                let chordCell: ChordCell = ChordCell(
                    chord: chordCell.chord,
                    chordCandidates: chordCell.chordCandidates,
                    startTime: chordCell.startTime - startTime,
                    duration: .zero
                )

                return [
                    chordCell.tokens(delta: delta).map { token in
                        let tokenId = vocab.chordId(token: token) ?? unkId
                        return InferenceResult(id: tokenId, probability: 1.0)
                    }
                ]
            }

            if previousResults.count > (maxChordLength - 2) {
                previousResults = Array(
                    previousResults.prefix(maxChordLength - 2)
                )
            }

            if endIndex >= notes.endIndex { break }
        }

        let result = ChordInferencerResult(
            key: key ?? Key(root: .C),
            chordCells: chordCells
        )
        return result
    }
}

extension ChordInferencer {
    private func inference(
        tokens: [String],
        previousResults: [[InferenceResult]]? = nil
    ) async throws -> [[InferenceResult]] {
        var tokenIds: [Int] = []

        tokenIds.reserveCapacity(maxMelodyLength)
        tokenIds.append(sosId)
        tokenIds.append(
            contentsOf:
                tokens
                .prefix(maxMelodyLength - 2)
                .map { token in
                    return vocab.melodyId(token: token) ?? unkId
                }
        )
        tokenIds.append(eosId)

        if tokenIds.count < maxMelodyLength {
            tokenIds.append(
                contentsOf: Array(
                    repeating: padId,
                    count: maxMelodyLength - tokenIds.count
                )
            )
        }

        let melodyArray: MLShapedArray<Int32> = MLShapedArray<Int32>(
            scalars: tokenIds.map(Int32.init),
            shape: [1, maxMelodyLength]
        )

        let melodyTokens = MLMultiArray(melodyArray)

        let chordInferenceResults = try await generateOutputSequence(
            melodyTokens: melodyTokens,
            previousResults: previousResults,
            topK: 5,
            temperature: 0.9
        )

        return chordInferenceResults
    }

    private func generateOutputSequence(
        melodyTokens: MLMultiArray,
        previousResults: [[InferenceResult]]? = nil,
        topK: Int? = 5,
        temperature: Float = 0.9
    ) async throws -> [[InferenceResult]] {
        var results: [[InferenceResult]] = previousResults ?? []

        var chordArray: MLShapedArray<Int32> = MLShapedArray(
            repeating: Int32(padId),
            shape: [1, maxChordLength]
        )

        chordArray[scalarAt: [0, 0]] = Int32(sosId)
        for (index, result) in results.enumerated() {
            let tokenId: Int = result.first?.id ?? unkId
            chordArray[scalarAt: [0, index + 1]] = Int32(tokenId)
        }

        for index in (results.count + 1)..<maxChordLength {
            let chordInput: MLMultiArray = MLMultiArray(chordArray)

            let input: TransformerChordInferenceInput =
                TransformerChordInferenceInput(
                    melody_tokens: melodyTokens,
                    chord_input: chordInput
                )
            let output: TransformerChordInferenceOutput = try await model.prediction(
                input: input
            )

            let logits: MLShapedArray<Float> = output.chord_outputShapedArray

            let position: Int = results.count

            let candidates: [InferenceResult] = try topKTokens(
                from: logits,
                at: position,
                temperature: temperature,
                k: topK ?? 5
            )

            if candidates.first?.id ?? eosId == eosId { break }

            results.append(candidates)

            chordArray[scalarAt: [0, index]] = Int32(
                results.last?.first?.id ?? unkId
            )
        }

        return results
    }

    private func topKTokens(
        from logits: MLShapedArray<Float>,
        at position: Int,
        temperature: Float,
        k: Int
    ) throws -> [InferenceResult] {
        let vocabSize: Int = vocab.chord.count

        let positionLogits: [Float] = logits[0, position].map { slice in
            return (slice.scalar ?? .zero) / max(1e-6, temperature)
        }

        let maxLogit: Float = positionLogits.max() ?? .zero
        let expVals: [Float] = positionLogits.map { logit in
            return exp(logit - maxLogit)
        }
        let sumExp: Float = expVals.reduce(.zero, +)

        guard sumExp > 0 else {
            let pairs = positionLogits.enumerated()
                .map {
                    InferenceResult(id: $0.offset, probability: $0.element)
                }
                .sorted { $0.probability > $1.probability }

            return Array(pairs.prefix(min(k, vocabSize)))
        }

        let probs: [Float] = expVals.map { value in
            return value / sumExp
        }

        let ranked = probs.enumerated()
            .map { InferenceResult(id: $0.offset, probability: $0.element) }
            .sorted { $0.probability > $1.probability }

        return Array(ranked.prefix(min(k, vocabSize)))
    }

    private func convertToChordCells(
        _ inferenceResults: [[InferenceResult]],
        threshold: Float = 0.4
    ) -> [ChordCell] {
        func convertToChordCell(
            position: TimeInterval,
            root: [InferenceResult],
            type: [InferenceResult]
        ) -> ChordCell {
            let candidates:
                [(
                    rootId: Int, typeId: Int,
                    probability: Float
                )] = root.flatMap { rootResult in
                    return type.map { typeResult in
                        return (
                            rootId: rootResult.id, typeId: typeResult.id,
                            probability: rootResult.probability
                                * typeResult.probability
                        )
                    }
                }

            let chordCandidates: [Chord] = Array(
                candidates.compactMap {
                    (rootId: Int, typeId: Int, probability: Float) in
                    guard
                        let rootToken = vocab.chordToken(
                            id: rootId
                        ),
                        let chordRoot = NoteName(token: rootToken)
                    else {
                        return nil
                    }

                    guard
                        let typeToken = vocab.chordToken(
                            id: typeId
                        ),
                        let chordQuality = ChordQuality(
                            token: typeToken
                        )
                    else { return nil }

                    let chord: Chord = Chord(
                        root: chordRoot,
                        quality: chordQuality
                    )

                    return chord
                }.prefix(5)
            )

            let chordCell: ChordCell = ChordCell(
                chord: chordCandidates.first,
                chordCandidates: chordCandidates,
                startTime: position,
                duration: .zero
            )

            return chordCell
        }

        var chordCells: [ChordCell] = []

        var position: TimeInterval?
        var root: [InferenceResult]?
        var type: [InferenceResult]?

        for result in inferenceResults {
            guard let firstResult: InferenceResult = result.first,
                let firstResultToken: String = vocab.chordToken(
                    id: firstResult.id
                )
            else {
                continue
            }

            if firstResultToken.hasPrefix("TimeShift_") {
                if let prevPosition = position,
                    let prevRoot = root,
                    let prevType = type,
                    let probability = prevRoot.first?.probability
                {
                    if probability >= threshold {
                        let chordCell: ChordCell = convertToChordCell(
                            position: prevPosition,
                            root: prevRoot,
                            type: prevType
                        )

                        chordCells.append(
                            chordCell
                        )
                    }

                    root = nil
                    type = nil
                }

                if let delta: TimeInterval = TimeInterval(
                    token: firstResultToken
                ) {
                    position = (position ?? 0) + delta
                }
            } else if firstResultToken.hasPrefix("Root_") {
                root = result
            } else if firstResultToken.hasPrefix("Type_") {
                type = result
            }
        }

        if let prevPosition = position,
            let prevRoot = root,
            let prevType = type,
            let probability = prevRoot.first?.probability
        {
            if probability >= threshold {
                let chordCell: ChordCell = convertToChordCell(
                    position: prevPosition,
                    root: prevRoot,
                    type: prevType
                )

                chordCells.append(
                    chordCell
                )
            }

            position = nil
            root = nil
            type = nil
        }

        return chordCells
    }
}

private struct Vocab {
    let melody: [String]
    let chord: [String]

    func melodyId(token: String) -> Int? {
        melody.firstIndex(of: token)
    }

    func chordId(token: String) -> Int? {
        chord.firstIndex(of: token)
    }

    func melodyToken(id: Int) -> String? {
        guard melody.indices.contains(id) else { return nil }
        return melody[id]
    }

    func chordToken(id: Int) -> String? {
        guard chord.indices.contains(id) else { return nil }
        return chord[id]
    }
}

extension Vocab: Codable {
    enum CodingKeys: String, CodingKey {
        case melody = "melody_tokens"
        case chord = "chord_tokens"
    }
}

private struct InferenceResult {
    let id: Int
    let probability: Float
}

extension NoteName {
    fileprivate init?(token: String) {
        var noteNameString: String? = nil

        if token.hasPrefix("Root_") {
            noteNameString = token.replacingOccurrences(of: "Root_", with: "")
        }
        if token.hasPrefix("Key_") {
            noteNameString = token.replacingOccurrences(of: "Key_", with: "")
        }

        guard let noteNameString else { return nil }

        switch noteNameString {
        case "C": self = .C
        case "C#": self = .Cs
        case "D": self = .D
        case "D#": self = .Ds
        case "E": self = .E
        case "F": self = .F
        case "F#": self = .Fs
        case "G": self = .G
        case "G#": self = .Gs
        case "A": self = .A
        case "A#": self = .As
        case "B": self = .B
        default: return nil
        }
    }
}

extension ChordQuality {
    fileprivate init?(token: String) {
        guard token.hasPrefix("Type_") else { return nil }

        let qualityString = token.replacingOccurrences(of: "Type_", with: "")

        switch qualityString {
        case "M": self = .maj
        case "M7": self = .maj7
        case "M9": self = .maj9
        case "m": self = .min
        case "m7": self = .min7
        case "7": self = .dom7
        case "9": self = .dom9
        case "dim": self = .dim
        case "dim7": self = .dim7
        case "m7b5": self = .halfDim7
        default: return nil
        }
    }
}

extension TimeInterval {
    fileprivate init?(token: String) {
        guard token.hasPrefix("TimeShift_") else { return nil }

        guard
            let delta = TimeInterval(
                token.replacingOccurrences(of: "TimeShift_", with: "")
            )
        else { return nil }

        self = delta * 0.1
    }
}

extension NoteName {
    fileprivate var chormaIndex: Int {
        switch self {
        case .C: return 0
        case .Cs: return 1
        case .Db: return 1
        case .D: return 2
        case .Ds: return 3
        case .Eb: return 3
        case .E: return 4
        case .F: return 5
        case .Fs: return 6
        case .Gb: return 6
        case .G: return 7
        case .Gs: return 8
        case .Ab: return 8
        case .A: return 9
        case .As: return 10
        case .Bb: return 10
        case .B: return 11
        }
    }
}

extension Note {
    fileprivate func tokens(delta: Int) -> [String] {
        var tokens: [String] = []

        let chromaIndex = self.name.chormaIndex  // 0..11
        let duration = max(
            1,
            min(81, Int((self.duration * 10.0).rounded()))
        )  // 1..81

        let timeShiftToken = "TimeShift_\(delta)"
        let pitchToken = "Pitch_\(chromaIndex)"
        let durationToken = "Duration_\(duration)"

        tokens.append(timeShiftToken)
        tokens.append(pitchToken)
        tokens.append(durationToken)

        return tokens
    }
}

extension ChordCell {
    fileprivate func tokens(delta: Int) -> [String] {
        guard let chord else { return [] }

        var tokens: [String] = []

        let root = chord.root.description
        let quality = chord.quality.description

        let timeShiftToken = "TimeShift_\(delta)"
        let rootToken = "Root_\(root)"
        let qualityToken = "Type_\(quality)"

        tokens.append(timeShiftToken)
        tokens.append(rootToken)
        tokens.append(qualityToken)

        return tokens
    }
}
