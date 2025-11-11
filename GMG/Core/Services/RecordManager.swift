//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import AVFAudio
import Combine
import Foundation
internal import UniformTypeIdentifiers

final class RecordManager {
    private var audioRecorder: AVAudioRecorder?

    let isRecordingPublisher: CurrentValueSubject<Bool, Never>
    let recordedDurationPublisher: CurrentValueSubject<TimeInterval, Never>
    let audioLevelPublisher: CurrentValueSubject<Float, Never>

    private var cancellables: Set<AnyCancellable>

    init() {
        self.audioRecorder = nil

        self.isRecordingPublisher = CurrentValueSubject<Bool, Never>(false)
        self.recordedDurationPublisher =
            CurrentValueSubject<TimeInterval, Never>(.zero)
        self.audioLevelPublisher = CurrentValueSubject<Float, Never>(.zero)

        self.cancellables = Set<AnyCancellable>()
    }

    func record() throws {
        try AudioConductor.shared.setAudioMode(.record)

        do {
            let url: URL = URL.temporaryDirectory
                .appending(component: "recording-\(Date().ISO8601Format()).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 48_000,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            ]

            let audioRecorder: AVAudioRecorder = try AVAudioRecorder(
                url: url,
                settings: settings
            )

            audioRecorder.isMeteringEnabled = true
            audioRecorder.record()

            Timer.publish(
                every: 0.1,
                on: RunLoop.main,
                in: RunLoop.Mode.common
            )
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }

                self.updateMeter()
                self.updateRecordedDuration()
            }
            .store(in: &cancellables)

            self.audioRecorder = audioRecorder

            self.isRecordingPublisher.send(audioRecorder.isRecording)
        } catch {
            _ = stop()
            throw error
        }
    }

    func stop() -> URL? {
        try? AudioConductor.shared.setAudioMode(nil)

        guard let audioRecorder else { return nil }

        audioRecorder.stop()

        self.audioRecorder = nil
        self.cancellables.removeAll()

        self.isRecordingPublisher.send(audioRecorder.isRecording)

        return audioRecorder.url
    }

    private func updateRecordedDuration() {
        guard let audioRecorder else { return }

        let recordedDuration: TimeInterval = audioRecorder.currentTime

        self.recordedDurationPublisher.send(recordedDuration)
    }

    private func updateMeter() {
        guard let audioRecorder else { return }

        audioRecorder.updateMeters()

        let averagePower: Float = audioRecorder.averagePower(forChannel: 0)
        let normalizedLevel: Float = normalizeLevel(averagePower)

        self.audioLevelPublisher.send(normalizedLevel)
    }

    private func normalizeLevel(_ dB: Float, minDb: Float = -30) -> Float {
        let clamped: Float = min(0, max(minDb, dB))
        return (clamped - minDb) / (-minDb)
    }
}
