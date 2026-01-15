//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import AVFAudio
import Combine
import Foundation
import Tonic

enum ScorePlayerError: Error {
    case audioFileNotFound
    case soundBankNotFound
}

protocol ScorePlayer {
    var playerMutedPublisher: CurrentValueSubject<Bool, Never> { get }
    var playheadPublisher: CurrentValueSubject<Playhead, Never> { get }
    var currentInstrumentPublisher: CurrentValueSubject<Instrument, Never> { get }

    func prepareToPlay() throws
    func cleanupAfterPlay()

    func play()
    func pause()
    func stop()
    func seek(to time: TimeInterval)
    func seek(chordCell: ChordCell)

    func play(chord: Chord)
    func setPlayerMuted(_ isMuted: Bool)
    func prepareChordCells()

    func setInstrument(_ instrument: Instrument)
}

final class DefaultScorePlayer: ScoreAudioEngineBase, ScorePlayer {
    private var pausedTime: TimeInterval
    private var chordPlayTask: Task<Void, Never>?

    let playerMutedPublisher: CurrentValueSubject<Bool, Never>
    let playheadPublisher: CurrentValueSubject<Playhead, Never>
    let currentInstrumentPublisher: CurrentValueSubject<Instrument, Never>

    private var cancellables: Set<AnyCancellable>

    override init(score: Score) {
        self.pausedTime = .zero
        self.chordPlayTask = nil
        self.playerMutedPublisher = CurrentValueSubject<Bool, Never>(false)
        self.playheadPublisher = CurrentValueSubject<Playhead, Never>(
            Playhead(
                isPlaying: false,
                elapsedTime: .zero
            )
        )
        self.currentInstrumentPublisher = CurrentValueSubject<Instrument, Never>(.piano)
        self.cancellables = Set<AnyCancellable>()

        super.init(score: score)
    }

    /// onAppear 시 실행될 메서드
    func prepareToPlay() throws {
        attachNodes()

        try activateAudioSession()
        try engine.start()

        try loadAudioFile(score.audioURL)

        // 코드 재생 준비
        try loadSoundBank(instrument: currentInstrumentPublisher.value)
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

        NotificationCenter.default.publisher(
            for: AVAudioSession.routeChangeNotification
        )
        .sink { [weak self] notification in
            guard let self else { return }

            do {
                let wasPlaying = self.player.isPlaying
                self.pause()

                try self.activateAudioSession()
                try self.engine.start()

                Task {
                    try? await Task.sleep(for: .seconds(0.1))
                    try? self.loadSoundBank()

                    if wasPlaying {
                        self.play()
                    }
                }
            } catch {
                Logger.error(String(describing: error))
            }
        }
        .store(in: &cancellables)
    }

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
        let wasPlaying = player.isPlaying

        self.pausedTime = time

        if wasPlaying {
            play()
        }
    }

    func seek(chordCell: ChordCell) {
        let wasPlaying = player.isPlaying

        self.pausedTime = chordCell.startTime

        if wasPlaying {
            play()
        } else {
            guard let chord = chordCell.chord else { return }
            play(chord: chord)
        }
    }

    func play(chord: Chord) {
        chordPlayTask?.cancel()

        chordPlayTask = Task {
            let tonicChord = chord.tonicChord
            let midiNotes = tonicChord.midiNoteNumbers(
                octave: currentInstrumentPublisher.value.octave
            )

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

    func setPlayerMuted(_ isMuted: Bool) {
        if isMuted {
            player.volume = 0.0
        } else {
            player.volume = 1.0
        }

        playerMutedPublisher.send(isMuted)
    }

    func setInstrument(_ instrument: Instrument) {
        do {
            try loadSoundBank(instrument: instrument)

            self.currentInstrumentPublisher.send(instrument)

            prepareChordCells()
        } catch {
            Logger.error(String(describing: error))
        }
    }

    func prepareChordCells() {
        let wasPlaying = player.isPlaying

        pause()

        super.prepareChordCells(
            octave: currentInstrumentPublisher.value.octave
        )

        if wasPlaying {
            play()
        }
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
