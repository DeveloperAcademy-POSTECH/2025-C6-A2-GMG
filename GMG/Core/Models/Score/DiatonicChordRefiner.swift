//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

enum DiatonicChordRefiner {
    /// Ionian(메이저) 다이아토닉 기준으로 코드 셀을 정제한 Score를 반환한다.
    /// - Note: 마이너 키는 고려하지 않는다.
    static func refine(score: Score) -> Score {
        let refinedChordCells: [ChordCell] = score.chordCells.map { cell in
            guard let chord = cell.chord else { return cell }

            if isDiatonic(chord: chord, key: score.key) {
                return cell
            }

            guard
                let replacement: Chord = cell.chordCandidates.first(where: {
                    isDiatonic(chord: $0, key: score.key)
                })
            else {
                return cell
            }

            return ChordCell(
                chord: replacement,
                chordCandidates: cell.chordCandidates,
                startTime: cell.startTime,
                duration: cell.duration
            )
        }

        return Score(
            id: score.id,
            title: score.title,
            key: score.key,
            audioURL: score.audioURL,
            totalDuration: score.totalDuration,
            createdAt: score.createdAt,
            updatedAt: score.updatedAt,
            notes: score.notes,
            chordCells: refinedChordCells,
            audioLevels: score.audioLevels,
            isDeleted: score.isDeleted
        )
    }

    private static func isDiatonic(chord: Chord, key: Key) -> Bool {
        let interval: Int = intervalBetween(key.root, chord.root)

        guard let degree = IonianDegree(rawValue: interval) else { return false }

        return degree.allowedQualities.contains(chord.quality)
    }

    private static func intervalBetween(_ root: NoteName, _ note: NoteName) -> Int {
        let semitone = { (name: NoteName) -> Int in
            switch name {
            case .C: return 0
            case .Cs, .Db: return 1
            case .D: return 2
            case .Ds, .Eb: return 3
            case .E, .Fb: return 4
            case .F: return 5
            case .Fs, .Gb: return 6
            case .G: return 7
            case .Gs, .Ab: return 8
            case .A: return 9
            case .As, .Bb: return 10
            case .B: return 11
            }
        }

        return (semitone(note) - semitone(root) + 12) % 12
    }
}

private enum IonianDegree: Int {
    case I = 0
    case ii = 2
    case iii = 4
    case IV = 5
    case V = 7
    case vi = 9
    case viidim = 11

    var allowedQualities: Set<ChordQuality> {
        switch self {
        case .I:
            return [.maj, .maj7]
        case .ii:
            return [.min, .min7]
        case .iii:
            return [.min, .min7]
        case .IV:
            return [.maj, .maj7]
        case .V:
            return [.maj, .dom7]
        case .vi:
            return [.min, .min7]
        case .viidim:
            return [.dim, .halfDim7]
        }
    }
}
