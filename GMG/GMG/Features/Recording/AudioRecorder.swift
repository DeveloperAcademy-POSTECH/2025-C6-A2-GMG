//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import AVFAudio
import AudioKit
import AudioKitEX
import Combine
import SoundpipeAudioKit

enum AudioRecorderError: Error {
    case NotAvailableEngineInput
}

final class AudioRecorder {
    private var engine: AudioEngine?

    private var filter: HighPassFilter?
    private var fader: Fader?
    private var pitchTap: PitchTap?
    private var fftTap: FFTTap?

    private var recorder: NodeRecorder?

    private var previousTime: Date = Date()
    private(set) var pitches:
        [(frequency: Float, amplitude: Float, duration: Float)] =
            []
    private(set) var fftMagnitudes: [Float] = [] {
        didSet {
            fftMangitudesPublisher.send(fftMagnitudes)
        }
    }
    private(set) var fftMangitudesPublisher:
        PassthroughSubject<[Float], Never> = PassthroughSubject<
            [Float], Never
        >()

    private(set) var isRecording: Bool = false {
        didSet {
            isRecordingPublisher.send(isRecording)
        }
    }
    private(set) var isRecordingPublisher: PassthroughSubject<Bool, Never> =
        PassthroughSubject<Bool, Never>()

    private(set) var recordedDuration: TimeInterval = 0.0 {
        didSet {
            recordedDurationPublisher.send(recordedDuration)
        }
    }
    private(set) var recordedDurationPublisher:
        PassthroughSubject<TimeInterval, Never> = PassthroughSubject<
            TimeInterval, Never
        >()

    init() throws {
        try setupRecoder()
        try configureSession()
    }

    func startRecord() throws {
        try AVAudioSession.sharedInstance().setActive(true)
        try engine?.start()

        self.pitches = []
        self.previousTime = Date()

        pitchTap?.start()
        fftTap?.start()
        try recorder?.record()

        self.isRecording = true
    }

    func stopRecord() throws {
        recorder?.stop()
        fftTap?.stop()
        pitchTap?.stop()

        engine?.stop()
        try AVAudioSession.sharedInstance().setActive(false)

        self.isRecording = false
    }

    func retakeRecord() throws {
        try stopRecord()

        try recorder?.reset()

        self.fftMagnitudes = []
        self.recordedDuration = 0.0
    }

    private func setupRecoder() throws {
        let engine = AudioEngine()

        guard let input = engine.input else {
            throw AudioRecorderError.NotAvailableEngineInput
        }

        let filter = HighPassFilter(
            input,
            cutoffFrequency: 200.0,
            resonance: .zero
        )
        let fader = Fader(filter, gain: .zero)
        let pitchTap = PitchTap(filter) { [weak self] frequencies, amplitudes in
            self?.pitchTapHandler(
                frequencies: frequencies,
                amplitudes: amplitudes
            )
        }
        let fftTap = FFTTap(filter) { [weak self] fftMagnitudes in
            self?.fftTapHandler(fftMagnitudes: fftMagnitudes)
        }

        let recorder = try NodeRecorder(node: input)

        engine.output = fader

        self.engine = engine

        self.filter = filter
        self.fader = fader
        self.pitchTap = pitchTap
        self.fftTap = fftTap

        self.recorder = recorder
    }

    private func pitchTapHandler(frequencies: [Float], amplitudes: [Float]) {
        guard let frequency = frequencies.first,
            let amplitude = amplitudes.first
        else { return }

        let duration = Float(Date().timeIntervalSince(self.previousTime))

        self.pitches.append(
            (frequency: frequency, amplitude: amplitude, duration: duration)
        )

        self.previousTime = Date()
    }

    private func fftTapHandler(fftMagnitudes: [Float]) {
        self.fftMagnitudes = fftMagnitudes

        if let recorder {
            self.recordedDuration = recorder.recordedDuration
        }
    }

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()

        try session.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.defaultToSpeaker, .allowBluetoothHFP]
        )
        try session.setPreferredSampleRate(48_000)
        try session.setPreferredIOBufferDuration(0.005)
    }
}
