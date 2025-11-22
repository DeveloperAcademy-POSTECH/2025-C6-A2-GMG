//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import AVFAudio
import Foundation
import Tonic

/// ScorePlayer와 ScoreAudioRenderer의 공통 로직을 담당하는 베이스 클래스
class ScoreAudioEngineBase {
    let score: Score
    let engine: AVAudioEngine
    let sampler: AVAudioUnitSampler
    let sequencer: AVAudioSequencer
    let player: AVAudioPlayerNode

    private(set) var audioFile: AVAudioFile?
    private(set) var sampleRate: Double
    private(set) var totalFrames: AVAudioFramePosition

    init(score: Score) {
        self.score = score

        let engine = AVAudioEngine()
        self.engine = engine

        self.sampler = AVAudioUnitSampler()
        self.sequencer = AVAudioSequencer(audioEngine: engine)
        self.player = AVAudioPlayerNode()

        self.audioFile = nil

        self.sampleRate = Constants.sampleRate
        self.totalFrames = .zero
    }

    func prepareToExport() throws {
        attachNodes()
        try loadAudioFile(score.audioURL)
        scheduleAudioFile(from: .zero)
        try loadSoundBank()
        prepareChordCells()
    }

    func attachNodes() {
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
    }

    func loadAudioFile(_ url: URL) throws {
        let audioFile: AVAudioFile = try AVAudioFile(forReading: url)

        let format: AVAudioFormat = audioFile.processingFormat

        engine.connect(player, to: engine.mainMixerNode, format: format)

        sampleRate = format.sampleRate
        totalFrames = audioFile.length

        self.audioFile = audioFile
    }

    func loadSoundBank() throws {
        guard
            let url = Bundle.main.url(
                forResource: "KAWAI good piano",
                withExtension: "sf2"
            )
        else { throw ScorePlayerError.soundBankNotFound }

        try sampler.loadSoundBankInstrument(
            at: url,
            program: .zero,
            bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
            bankLSB: UInt8(kAUSampler_DefaultBankLSB)
        )
    }

    func scheduleAudioFile(from startTime: TimeInterval) {
        guard let audioFile = self.audioFile else { return }

        player.stop()

        let startFrame = AVAudioFramePosition(startTime * sampleRate)
        let availableFrames = audioFile.length - startFrame
        guard availableFrames > 0 else { return }

        let frameCount = AVAudioFrameCount(availableFrames)

        player.scheduleSegment(
            audioFile,
            startingFrame: startFrame,
            frameCount: frameCount,
            at: nil,
            completionHandler: nil
        )
    }

    func prepareChordCells() {
        for track in Array(sequencer.tracks) {
            sequencer.removeTrack(track)
        }

        let chordCells: [ChordCell] = score.retrieveAllChordCells()
        let audioDuration: TimeInterval = score.totalDuration

        sequencer.rate = 60 / 120

        let track: AVMusicTrack = sequencer.createAndAppendTrack()
        track.lengthInSeconds = audioDuration

        let filteredChordCells: [ChordCell] = chordCells.filter { chordCell in
            chordCell.chord != nil && chordCell.startTime < audioDuration
        }

        for index in 0..<max(0, filteredChordCells.count - 1) {
            let currentChordCell: ChordCell = filteredChordCells[index]
            let nextChordCell: ChordCell = filteredChordCells[index + 1]

            guard let chord = currentChordCell.chord else { continue }

            let position: TimeInterval = currentChordCell.startTime
            let duration: TimeInterval =
                nextChordCell.startTime - position
            let tonicChord: Tonic.Chord = chord.tonicChord
            let midiNotes: [Int8] = tonicChord.midiNoteNumbers

            for midiNote in midiNotes {
                let noteEvent: AVExtendedNoteOnEvent = AVExtendedNoteOnEvent(
                    midiNote: Float(midiNote),
                    velocity: 100,
                    groupID: .zero,
                    duration: duration
                )
                track.addEvent(noteEvent, at: position)
            }
        }

        if let lastChordCell: ChordCell = filteredChordCells.last,
            let chord: Chord = lastChordCell.chord
        {
            let position: TimeInterval = lastChordCell.startTime
            let duration: TimeInterval = audioDuration - position
            let tonicChord: Tonic.Chord = chord.tonicChord
            let midiNotes: [Int8] = tonicChord.midiNoteNumbers

            for midiNote in midiNotes {
                let noteEvent: AVExtendedNoteOnEvent = AVExtendedNoteOnEvent(
                    midiNote: Float(midiNote),
                    velocity: 100,
                    groupID: .zero,
                    duration: duration
                )
                track.addEvent(noteEvent, at: position)
            }
        }
    }
}

// MARK: - Extensions

extension Chord {
    var tonicChord: Tonic.Chord {
        var root: NoteClass = .C
        switch self.root {
        case .C: root = .C
        case .Cs: root = .Cs
        case .Db: root = .Db
        case .D: root = .D
        case .Ds: root = .Ds
        case .Eb: root = .Eb
        case .E: root = .E
        case .Fb: root = .Fb
        case .F: root = .F
        case .Fs: root = .Fs
        case .Gb: root = .Gb
        case .G: root = .G
        case .Gs: root = .Gs
        case .Ab: root = .Ab
        case .A: root = .A
        case .As: root = .As
        case .Bb: root = .Bb
        case .B: root = .B
        }

        var type: ChordType = .major
        switch self.quality {
        case .maj: type = .major
        case .maj7: type = .maj7
        case .maj9: type = .maj9
        case .min: type = .minor
        case .min7: type = .min7
        case .dom7: type = .dom7
        case .dom9: type = .dom9
        case .dim: type = .dim
        case .dim7: type = .dim7
        case .halfDim7: type = .halfDim7
        }

        let tonicChord: Tonic.Chord = Tonic.Chord(root, type: type)

        return tonicChord
    }
}

extension Tonic.Chord {
    var midiNoteNumbers: [Int8] {
        let pitches: [Pitch] = self.pitches(octave: 3)
        let midiNoteNumbers: [Int8] = pitches.map { pitch in
            return pitch.midiNoteNumber
        }

        return midiNoteNumbers
    }
}
