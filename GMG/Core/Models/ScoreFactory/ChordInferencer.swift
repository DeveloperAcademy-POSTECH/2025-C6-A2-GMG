//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import CoreML

struct ChordInferencerResult {
    let key: Key
    let chordCells: [ChordCell]
}

final class ChordInferencer {
    private let model: TransformerChordInference
    private let vocab: Vocab

    private var maxSrcLen: Int = 512
    private var maxTgtLen: Int = 256

    private let padIndex: Int = 0
    private let sosIndex: Int = 1
    private let eosIndex: Int = 2
    private let unkIndex: Int = 3

    init() throws {
        self.model = try TransformerChordInference()

        if let melodyDesc = model.model.modelDescription
            .inputDescriptionsByName["melody_tokens"]?.multiArrayConstraint,
            let chordDesc = model.model.modelDescription
                .inputDescriptionsByName["chord_input"]?.multiArrayConstraint
        {

            if melodyDesc.shape.count == 2,
                let len = melodyDesc.shape[1].intValue as Int?
            {
                self.maxSrcLen = max(1, len)
            }
            if chordDesc.shape.count == 2,
                let len = chordDesc.shape[1].intValue as Int?
            {
                self.maxTgtLen = max(2, len)
            }
        }

        let vocabUrl = Bundle.main.url(
            forResource: "TransformerChordInferenceVocab",
            withExtension: "json"
        )!
        let vocabData = try Data(contentsOf: vocabUrl)
        self.vocab = try JSONDecoder().decode(Vocab.self, from: vocabData)
    }

    func inference(notes: [Note]) throws -> ChordInferencerResult {
        let tokenStrings: [String] = tokenizeNotes(notes)
        let outputTokens: [String] = try inference(tokenStrings: tokenStrings)

        var keyRoot: NoteName = .C

        if let keyToken: String = outputTokens.first {
            let keyString: String = keyToken.replacingOccurrences(
                of: "Key_",
                with: ""
            )

            switch keyString {
            case "C": keyRoot = .C
            case "C#": keyRoot = .Cs
            case "D": keyRoot = .D
            case "D#": keyRoot = .Ds
            case "E": keyRoot = .E
            case "F": keyRoot = .F
            case "F#": keyRoot = .Fs
            case "G": keyRoot = .G
            case "G#": keyRoot = .Gs
            case "A": keyRoot = .A
            case "A#": keyRoot = .As
            case "B": keyRoot = .B
            default: break
            }
        }

        let key: Key = Key(root: keyRoot)

        let chordCells: [ChordCell] = convertToChordCells(outputTokens)
        let result: ChordInferencerResult = ChordInferencerResult(
            key: key,
            chordCells: chordCells
        )

        return result
    }

    // 노트 -> 토큰 문자열 변환 (클램프 + 접두사 수정)
    private func tokenizeNotes(_ notes: [Note]) -> [String] {
        var tokenStrings: [String] = []
        for note in notes {
            let posIdx = max(
                0,
                min(511, Int((note.startTime * 10.0).rounded()))
            )  // 0..511
            let pitchIdx = note.name.chormaIndex  // 0..11
            let durIdx = max(1, min(81, Int((note.duration * 10.0).rounded())))  // 1..81

            let positionToken = "Position_\(posIdx)"
            let pitchToken = "Pitch_\(pitchIdx)"
            let durationToken = "Duration_\(durIdx)"

            tokenStrings.append(positionToken)
            tokenStrings.append(pitchToken)
            tokenStrings.append(durationToken)
        }
        return tokenStrings
    }

    func inference(tokenStrings: [String]) throws -> [String] {
        // melody 입력 길이
        let srcLen = maxSrcLen
        var tokens: [Int32] = Array(repeating: Int32(padIndex), count: srcLen)

        // BOS
        var write = 0
        tokens[write] = Int32(sosIndex)
        write += 1

        for tokenString in tokenStrings {
            if write >= srcLen - 1 { break }
            let idx = vocab.melody.firstIndex(of: tokenString) ?? unkIndex
            tokens[write] = Int32(idx)
            write += 1
        }
        // EOS
        tokens[min(write, srcLen - 1)] = Int32(eosIndex)

        // 멜로디 입력 배열 생성
        let melodyArray = MLShapedArray<Int32>(
            scalars: tokens,
            shape: [1, srcLen]
        )
        let melodyTokens = MLMultiArray(melodyArray)

        // 디코딩
        let chordIndices = try generateOutputSequence(
            melodyTokens: melodyTokens,
            topK: 5,
            temperature: 1.0
        )

        // 토큰 문자열 매핑 (BOS 제외)
        return chordIndices.dropFirst().map { index in
            if index >= 0 && index < vocab.chord.count {
                return vocab.chord[index]
            }
            return "<unk>"
        }
    }

    func convertToChordCells(_ tokens: [String]) -> [ChordCell] {
        var result: [ChordCell] = []

        var position: TimeInterval?
        var root: String?
        var type: String?
        for token in tokens {
            if token.hasPrefix("Position_") {
                if let prevPosition = position, let prevRoot = root,
                    let prevType = type
                {
                    let prevChord = convertToChord(
                        root: prevRoot,
                        type: prevType
                    )

                    result.append(
                        ChordCell(
                            chord: prevChord,
                            chordCandidates: [prevChord],
                            startTime: prevPosition
                        )
                    )

                    position = nil
                    root = nil
                    type = nil
                }
                position =
                    (TimeInterval(
                        token.replacingOccurrences(of: "Position_", with: "")
                    ) ?? 0.0) * 0.1
                if position == 0.0 {
                    position = nil
                }
            } else if token.hasPrefix("Root_") {
                root = token.replacingOccurrences(of: "Root_", with: "")
            } else if token.hasPrefix("Type_") {
                type = token.replacingOccurrences(of: "Type_", with: "")
            }
        }

        if let prevPosition = position, let prevRoot = root, let prevType = type
        {
            let prevChord = convertToChord(root: prevRoot, type: prevType)

            result.append(
                ChordCell(
                    chord: prevChord,
                    chordCandidates: [prevChord],
                    startTime: prevPosition
                )
            )

            position = nil
            root = nil
            type = nil
        }

        return result
    }

    private func convertToChord(root: String, type: String) -> Chord {
        var noteName: NoteName = .C
        switch root {
        case "C":
            noteName = .C
        case "C#":
            noteName = .Cs
        case "D":
            noteName = .D
        case "D#":
            noteName = .Ds
        case "E":
            noteName = .E
        case "F":
            noteName = .F
        case "F#":
            noteName = .Fs
        case "G":
            noteName = .G
        case "G#":
            noteName = .Gs
        case "A":
            noteName = .A
        case "A#":
            noteName = .As
        case "B":
            noteName = .B
        default:
            break
        }

        var chordQuality: ChordQuality = .maj
        switch type {
        case "maj":
            chordQuality = .maj
        case "maj7":
            chordQuality = .maj7
        case "M9":
            chordQuality = .maj9
        case "m":
            chordQuality = .min
        case "m7":
            chordQuality = .min7
        case "7":
            chordQuality = .dom7
        case "9":
            chordQuality = .dom9
        case "dim":
            chordQuality = .dim
        case "o7":
            chordQuality = .dim7
        case "ø7":
            chordQuality = .halfDim7
        default:
            break
        }

        return Chord(root: noteName, quality: chordQuality)
    }

    private func generateOutputSequence(
        melodyTokens: MLMultiArray,
        topK: Int? = 5,
        temperature: Float = 0.9
    ) throws -> [Int] {
        var chordIndices: [Int] = [sosIndex]

        // 모델 기대 타깃 길이로 배열 준비
        let tgtLen = maxTgtLen
        let chordInput = try MLMultiArray(
            shape: [1, tgtLen] as [NSNumber],
            dataType: .int32
        )

        for _ in 0..<tgtLen {
            // 입력 채우기
            for i in 0..<tgtLen {
                let val = (i < chordIndices.count) ? chordIndices[i] : padIndex
                chordInput[[0, i] as [NSNumber]] = NSNumber(value: val)
            }

            let input = TransformerChordInferenceInput(
                melody_tokens: melodyTokens,
                chord_input: chordInput
            )
            let output = try model.prediction(input: input)
            let logits = output.chord_output

            // step 위치의 다음 토큰 로짓 사용
            let pos = chordIndices.count - 1
            let nextToken = try sampleNextToken(
                from: logits,
                at: pos,
                temperature: temperature,
                topK: topK
            )

            if nextToken == eosIndex { break }

            chordIndices.append(nextToken)

            if chordIndices.count >= tgtLen { break }
        }

        return chordIndices
    }

    // logits: [1, T, V] 또는 [1, V, T] 자동 감지 + top-k 지원
    private func sampleNextToken(
        from logits: MLMultiArray,
        at position: Int,
        temperature: Float,
        topK: Int?
    ) throws -> Int {
        let vocabSize = vocab.chord.count
        let shape = logits.shape.map { $0.intValue }  // e.g., [1, 256, 354] or [1, 354, 256]
        guard shape.count == 3 else { throw NSError(domain: "shape", code: -1) }

        let isTV = (shape[2] == vocabSize)  // [1, T, V]
        let isVT = (shape[1] == vocabSize)  // [1, V, T]
        guard isTV || isVT else {
            throw NSError(domain: "vocab-mismatch", code: -2)
        }

        var positionLogits = [Float](repeating: 0, count: vocabSize)
        if isTV {
            guard position < shape[1] else {
                throw NSError(domain: "pos", code: -3)
            }
            for i in 0..<vocabSize {
                positionLogits[i] =
                    logits[[0, position, i] as [NSNumber]].floatValue
                    / max(1e-6, temperature)
            }
        } else {
            // [1, V, T]
            guard position < shape[2] else {
                throw NSError(domain: "pos", code: -4)
            }
            for i in 0..<vocabSize {
                positionLogits[i] =
                    logits[[0, i, position] as [NSNumber]].floatValue
                    / max(1e-6, temperature)
            }
        }

        // top-k 필터링: 상위 k 외는 -inf로 마스킹
        if let k = topK, k > 0, k < vocabSize {
            let sorted = positionLogits.enumerated().sorted {
                $0.element > $1.element
            }
            var mask = [Bool](repeating: false, count: vocabSize)
            for (j, pair) in sorted.enumerated() where j < k {
                mask[pair.offset] = true
            }
            for i in 0..<vocabSize where !mask[i] {
                positionLogits[i] = -Float.infinity
            }
        }

        // softmax
        let maxLogit = positionLogits.max() ?? 0
        var expVals = [Float](repeating: 0, count: vocabSize)
        var sumExp: Float = 0
        for i in 0..<vocabSize {
            let v = exp(positionLogits[i] - maxLogit)
            expVals[i] = v
            sumExp += v
        }
        if sumExp <= 0 {
            // 분포가 무의미하면 greedy로 폴백
            var bestIdx = 0
            var bestVal = -Float.infinity
            for i in 0..<vocabSize {
                let v = positionLogits[i]
                if v > bestVal {
                    bestVal = v
                    bestIdx = i
                }
            }
            return bestIdx
        }

        // top-k 샘플링: 확률 분포에서 샘플
        if let k = topK, k > 0 {
            var probs = [Float](repeating: 0, count: vocabSize)
            for i in 0..<vocabSize { probs[i] = expVals[i] / sumExp }

            let u = Float.random(in: 0..<1)
            var cum: Float = 0
            for i in 0..<vocabSize {
                cum += probs[i]
                if u <= cum { return i }
            }
            // 누적오차 방지용 폴백
            return probs.indices.max(by: { probs[$0] < probs[$1] }) ?? unkIndex
        } else {
            // greedy
            var bestIdx = 0
            var bestVal = -Float.infinity
            for i in 0..<vocabSize {
                let v = positionLogits[i]
                if v > bestVal {
                    bestVal = v
                    bestIdx = i
                }
            }
            return bestIdx
        }
    }

}

private struct Vocab: Codable {
    let melody: [String]
    let chord: [String]

    enum CodingKeys: String, CodingKey {
        case melody = "melody_tokens"
        case chord = "chord_tokens"
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
        case .Fb: return 4
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
