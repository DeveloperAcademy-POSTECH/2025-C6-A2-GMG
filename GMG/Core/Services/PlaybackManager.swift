//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import AVFAudio
import Combine
import Foundation

final class PlaybackManager: NSObject, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer?

    let isPlayingPublisher: CurrentValueSubject<Bool, Never>
    let playedDurationPublisher: CurrentValueSubject<TimeInterval, Never>
    let audioLevelPublisher: CurrentValueSubject<Float, Never>

    private var cancellables: Set<AnyCancellable>

    override init() {
        self.audioPlayer = nil

        self.isPlayingPublisher = CurrentValueSubject<Bool, Never>(false)
        self.playedDurationPublisher = CurrentValueSubject<TimeInterval, Never>(
            .zero
        )
        self.audioLevelPublisher = CurrentValueSubject<Float, Never>(.zero)

        self.cancellables = Set<AnyCancellable>()
    }

    func play(_ url: URL) throws {
        do {
            let audioPlayer: AVAudioPlayer = try AVAudioPlayer(contentsOf: url)

            audioPlayer.delegate = self
            audioPlayer.isMeteringEnabled = true
            audioPlayer.play()

            Timer.publish(
                every: 0.1,
                on: RunLoop.main,
                in: RunLoop.Mode.common
            )
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }

                self.updateMeter()
                self.updatePlayedDuration()
            }
            .store(in: &cancellables)

            self.audioPlayer = audioPlayer

            self.isPlayingPublisher.send(audioPlayer.isPlaying)
        } catch {
            stop()
            throw error
        }
    }

    func stop() {
        guard let audioPlayer else { return }

        audioPlayer.stop()

        self.audioPlayer = nil
        self.cancellables.removeAll()

        self.isPlayingPublisher.send(audioPlayer.isPlaying)
        self.playedDurationPublisher.send(audioPlayer.duration)
    }

    private func updateMeter() {
        guard let audioPlayer else { return }

        audioPlayer.updateMeters()

        let averagePower: Float = audioPlayer.averagePower(forChannel: 0)
        let normalizedLevel: Float = DecibelsNormalizer.normalize(averagePower)

        self.audioLevelPublisher.send(normalizedLevel)
    }

    private func updatePlayedDuration() {
        guard let audioPlayer else { return }

        let playedDuration: TimeInterval = audioPlayer.currentTime

        self.playedDurationPublisher.send(playedDuration)
    }

    // MARK: - AVAudioPlayerDelgate Implement

    func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        stop()
    }
}
