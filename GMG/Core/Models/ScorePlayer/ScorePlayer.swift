//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import AVFAudio
import Combine
import Foundation
import Tonic

enum ScorePlayerError: Error {
    case audioFileNotFound
    case soundBankNotFound
}

final class ScorePlayer {
    private let score: Score

    private let engine: AVAudioEngine

    private let sampler: AVAudioUnitSampler
    private let sequencer: AVAudioSequencer
    private let player: AVAudioPlayerNode

    private var audioFile: AVAudioFile?
    private var pausedTime: TimeInterval

    private var sampleRate: Double
    private var totalFrames: AVAudioFramePosition

    private var chordPlayTask: Task<Void, Never>?

    let playerMutedPublisher: CurrentValueSubject<Bool, Never>

    let playheadPublisher: CurrentValueSubject<Playhead, Never>

    private var cancellables: Set<AnyCancellable>

    init(score: Score) {
        self.score = score

        let engine = AVAudioEngine()

        self.engine = engine

        self.sampler = AVAudioUnitSampler()
        self.sequencer = AVAudioSequencer(audioEngine: engine)
        self.player = AVAudioPlayerNode()

        self.audioFile = nil
        self.pausedTime = .zero

        self.sampleRate = 48_000
        self.totalFrames = .zero

        self.chordPlayTask = nil

        self.playerMutedPublisher = CurrentValueSubject<Bool, Never>(false)

        self.playheadPublisher = CurrentValueSubject<Playhead, Never>(
            Playhead(
                isPlaying: false,
                elapsedTime: .zero
            )
        )

        self.cancellables = Set<AnyCancellable>()
    }

    /// onAppear 시 실행될 메서드
    func prepareToPlay() throws {
        try activateAudioSession()

        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)

        try loadAudioFile(score.audioURL)

        try engine.start()

        // 녹음 파일 재생 준비
        scheduleAudioFile(from: .zero)

        // 코드 재생 준비
        try loadSoundBank()

        // 시퀀서 설정
        prepareChordCells()

        // 타이머 설정
        Timer.publish(
            every: 0.1,
            on: RunLoop.main,
            in: RunLoop.Mode.common
        )
        .autoconnect()
        .sink { [weak self] _ in
            guard let self else { return }

            if self.currentPlaybackTime() >= self.score.totalDuration {
                self.stop()
            }

            self.playheadPublisher.send(
                Playhead(
                    isPlaying: self.player.isPlaying,
                    elapsedTime: self.currentPlaybackTime()
                )
            )
        }
        .store(in: &cancellables)

        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .sink { [weak self] notification in
                guard let self else { return }

                do {
                    try self.activateAudioSession()
                    try self.engine.start()
                } catch {
                    Logger.error(String(describing: error))
                }
            }
            .store(in: &cancellables)
    }

    func prepareToExport() throws {
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)

        try loadAudioFile(score.audioURL)

        try loadSoundBank()

        prepareChordCells()
    }

    /// onDisappear 시 실행될 메서드
    func cleanupAfterPlay() {
        try? deactivateAudioSession()

        cancellables.removeAll()

        engine.stop()
    }

    func play() {

        if engine.isRunning == false {
            try? engine.start()
        }

        scheduleAudioFile(from: pausedTime)
        player.play()

        do {
            /// Sequencer는 `rate`에 따라 재생 속도가 결정되므로 재생 시간을 변경시에는 `rate`를 곱해줘야 함
            sequencer.currentPositionInSeconds = max(
                .zero, pausedTime * Double(sequencer.rate) - 0.01)
            try sequencer.start()
        } catch {
            Logger.error(String(describing: error))
        }
    }

    func play(chord: Chord) {
        chordPlayTask?.cancel()

        chordPlayTask = Task {
            let tonicChord: Tonic.Chord = chord.tonicChord
            let midiNotes: [Int8] = tonicChord.midiNoteNumbers

            midiNotes.forEach { midiNote in
                sampler.startNote(
                    UInt8(midiNote),
                    withVelocity: 100,
                    onChannel: .zero
                )
            }

            await withTaskCancellationHandler {
                try? await Task.sleep(for: .seconds(1))
            } onCancel: {
                Task { @MainActor in
                    midiNotes.forEach { midiNote in
                        sampler.stopNote(
                            UInt8(midiNote),
                            onChannel: .zero
                        )
                    }
                }
            }

            guard !Task.isCancelled else { return }

            midiNotes.forEach { midiNote in
                sampler.stopNote(
                    UInt8(midiNote),
                    onChannel: .zero
                )
            }
        }
    }

    func pause() {
        let pausedTime = currentPlaybackTime()

        player.pause()
        sequencer.stop()

        self.pausedTime = pausedTime
    }

    func stop() {
        player.stop()
        sequencer.stop()
        pausedTime = .zero
    }

    func seek(to time: TimeInterval) {
        let wasPlaying: Bool = player.isPlaying

        self.pausedTime = time

        if wasPlaying {
            play()
        }
    }

    func seek(chordCell: ChordCell) {
        let wasPlaying: Bool = player.isPlaying

        self.pausedTime = chordCell.startTime

        if wasPlaying {
            play()
        } else {
            guard let chord: Chord = chordCell.chord else { return }
            play(chord: chord)
        }
    }

    func setPlayerMuted(_ isMuted: Bool) {
        if isMuted {
            player.volume = 0.0
        } else {
            player.volume = 1.0
        }

        playerMutedPublisher.send(isMuted)
    }

    func prepareChordCells() {
        pause()

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

        for chordCell in filteredChordCells {
            guard let chord: Chord = chordCell.chord else { continue }

            let position: TimeInterval = chordCell.startTime
            let clampedDuration = min(chordCell.duration, max(0, audioDuration - position))
            guard clampedDuration > 0 else { continue }

            let tonicChord: Tonic.Chord = chord.tonicChord
            let midiNotes: [Int8] = tonicChord.midiNoteNumbers

            for midiNote in midiNotes {
                let noteEvent: AVExtendedNoteOnEvent = AVExtendedNoteOnEvent(
                    midiNote: Float(midiNote),
                    velocity: 100,
                    groupID: .zero,
                    duration: clampedDuration
                )
                track.addEvent(noteEvent, at: position)
            }
        }
    }

    private func loadAudioFile(_ url: URL) throws {
        let audioFile: AVAudioFile = try AVAudioFile(forReading: url)

        let format: AVAudioFormat = audioFile.processingFormat

        engine.connect(player, to: engine.mainMixerNode, format: format)

        sampleRate = format.sampleRate
        totalFrames = audioFile.length

        self.audioFile = audioFile
    }

    private func loadSoundBank() throws {
        guard
            let url: URL = Bundle.main.url(
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

    private func scheduleAudioFile(from startTime: TimeInterval) {
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

    private func activateAudioSession() throws {
        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()

        try audioSession.setCategory(
            .playback,
            mode: .default,
            options: []
        )
        try audioSession.setActive(true)
    }

    private func deactivateAudioSession() throws {
        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()

        try audioSession.setActive(false)
    }

    private func currentPlaybackTime() -> TimeInterval {
        if player.isPlaying {
            return pausedTime + player.currentTime(sampleRate: sampleRate)
        } else {
            return pausedTime
        }
    }
}

extension Chord {
    fileprivate var tonicChord: Tonic.Chord {
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
    fileprivate var midiNoteNumbers: [Int8] {
        let pitches: [Pitch] = self.pitches(octave: 3)
        let midiNoteNumbers: [Int8] = pitches.map { pitch in
            return pitch.midiNoteNumber
        }

        return midiNoteNumbers
    }
}

extension AVAudioPlayerNode {
    fileprivate var currentFrame: AVAudioFramePosition {
        guard let lastRenderTime = self.lastRenderTime,
            let playerTime = self.playerTime(forNodeTime: lastRenderTime)
        else {
            return .zero
        }
        return playerTime.sampleTime
    }

    fileprivate func currentTime(sampleRate: Double) -> TimeInterval {
        return Double(currentFrame) / sampleRate
    }
}
