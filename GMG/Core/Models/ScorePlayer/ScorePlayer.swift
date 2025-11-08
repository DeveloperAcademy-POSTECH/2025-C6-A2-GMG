//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import AudioKit
import AudioKitEX
import Combine
import Foundation
import Tonic

final class ScorePlayer {
    private let score: Score

    private let midiSampler: MIDISampler
    private let sequencer: Sequencer
    private let audioPlayer: AudioPlayer

    let playheadPublisher: CurrentValueSubject<Playhead, Never>
    private var playheadPublisherTimer: AnyCancellable?

    init(score: Score) {
        self.score = score

        self.midiSampler = MIDISampler()
        self.sequencer = Sequencer()
        self.audioPlayer = AudioPlayer()

        self.playheadPublisher = CurrentValueSubject<Playhead, Never>(
            Playhead(
                isPlaying: false,
                elapsedTime: 0.0
            )
        )
        self.playheadPublisherTimer = nil
    }

    /// onAppear 시 실행될 메서드
    func prepareToPlay() throws {
        try AudioConductor.shared.setAudioMode(.playback)
        AudioConductor.shared.addOutput(midiSampler)
        AudioConductor.shared.addOutput(audioPlayer)
        try AudioConductor.shared.start()

        // 녹음 파일 재생 준비
        try self.audioPlayer.load(url: score.audioUrl)
        self.audioPlayer.isLooping = false

        // 코드 재생 준비
        try midiSampler.loadSoundFont("8MBGMSFX", preset: 0, bank: 0)
        midiSampler.volume = 0.8

        let chordCells: [ChordCell] = score.retrieveAllChordCells()
        let audioDuration: TimeInterval = score.totalDuration

        sequencer.tempo = 60

        let track: SequencerTrack = sequencer.addTrack(for: midiSampler)
        track.tempo = 60
        track.length = audioDuration

        let filteredChordCells: [ChordCell] = chordCells.filter { chordCell in
            chordCell.chord != nil && chordCell.startTime < audioDuration
        }

        for index in 0..<max(0, filteredChordCells.count - 1) {
            let currentChordCell: ChordCell = filteredChordCells[index]
            let nextChordCell: ChordCell = filteredChordCells[index + 1]

            guard let chord: Chord = currentChordCell.chord else { continue }

            let position: TimeInterval = currentChordCell.startTime
            let duration: TimeInterval =
                nextChordCell.startTime - position
            let tonicChord: Tonic.Chord = chordToTonicChord(chord)
            let midiNotes: [MIDINoteNumber] = chordToMIDINotes(tonicChord)

            for midiNote in midiNotes {
                track.add(
                    noteNumber: midiNote,
                    position: position,
                    duration: duration
                )
            }
        }

        if let lastChordCell: ChordCell = filteredChordCells.last,
            let chord: Chord = lastChordCell.chord
        {
            let position: TimeInterval = lastChordCell.startTime
            let duration: TimeInterval = audioDuration - position
            let tonicChord: Tonic.Chord = chordToTonicChord(chord)
            let midiNotes: [MIDINoteNumber] = chordToMIDINotes(tonicChord)

            for midiNote in midiNotes {
                track.add(
                    noteNumber: midiNote,
                    position: position,
                    duration: duration
                )
            }
        }

        self.sequencer.loopEnabled = false

        // 타이머 설정
        self.playheadPublisherTimer = Timer.publish(
            every: 0.1,
            on: RunLoop.main,
            in: RunLoop.Mode.default
        )
        .autoconnect()
        .sink { [weak self] _ in
            guard let self else { return }

            if self.playheadPublisher.value.elapsedTime
                >= self.score.totalDuration
            {
                self.stop()
            }

            self.playheadPublisher.send(
                Playhead(
                    isPlaying: self.audioPlayer.isPlaying,
                    elapsedTime: self.audioPlayer.currentTime
                )
            )
        }
    }

    /// onDisappear 시 실행될 메서드
    func cleanupAfterPlay() {
        self.playheadPublisherTimer?.cancel()
        self.playheadPublisherTimer = nil

        AudioConductor.shared.stop()
        AudioConductor.shared.removeOutput(midiSampler)
        AudioConductor.shared.removeOutput(audioPlayer)
        try? AudioConductor.shared.setAudioMode(nil)
    }

    func play() {
        self.audioPlayer.play()
        self.sequencer.play()
    }

    func pause() {
        self.audioPlayer.pause()
        self.sequencer.pause()
    }

    func stop() {
        self.audioPlayer.stop()
        self.sequencer.stop()
        self.sequencer.seek(to: .zero)
    }

    func seek(chordCell: ChordCell) {
        let isPlaying: Bool = audioPlayer.isPlaying

        stop()

        self.audioPlayer.seek(time: chordCell.startTime + 0.04)
        self.sequencer.seek(to: audioPlayer.currentTime)

        if isPlaying {
            play()
        } else {
            pause()

            guard let chord: Chord = chordCell.chord else { return }
            play(chord: chord)
        }
    }

    func play(chord: Chord) {
        let tonicChord: Tonic.Chord = chordToTonicChord(chord)
        let midiNotes: [MIDINoteNumber] = chordToMIDINotes(tonicChord)

        for midiNote in midiNotes {
            midiSampler.play(noteNumber: midiNote, velocity: 100, channel: 0)
        }

        Task {
            try? await Task.sleep(for: .seconds(1))
            for midiNote in midiNotes {
                midiSampler.stop(noteNumber: midiNote, channel: 0)
            }
        }
    }

    private func chordToTonicChord(_ chord: Chord) -> Tonic.Chord {
        var root: NoteClass = .C
        switch chord.root {
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
        switch chord.quality {
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

    private func chordToMIDINotes(_ chord: Tonic.Chord) -> [MIDINoteNumber] {
        let pitches = chord.pitches(octave: 3)
        let midiNotes = pitches.map { MIDINoteNumber($0.midiNoteNumber) }

        return midiNotes
    }
}
