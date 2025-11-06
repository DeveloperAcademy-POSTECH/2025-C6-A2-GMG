//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import AudioKit
import Combine
import Foundation

@Observable
final class PlaybackManager {
    private var audioPlayer: AudioPlayer

    private(set) var isPlayingPublisher: CurrentValueSubject<Bool, Never>

    private var isPlayingPublisherTimer: AnyCancellable?

    init() {
        self.audioPlayer = AudioPlayer()

        self.isPlayingPublisher = CurrentValueSubject<Bool, Never>(false)

        self.isPlayingPublisherTimer = nil
    }

    func play(_ url: URL) throws {
        try AudioConductor.shared.setAudioMode(.playback)
        AudioConductor.shared.addOutput(audioPlayer)
        try AudioConductor.shared.start()

        self.isPlayingPublisherTimer = Timer.publish(
            every: 0.1,
            on: RunLoop.main,
            in: RunLoop.Mode.default
        )
        .autoconnect()
        .sink { [weak self] _ in
            guard let self else { return }

            let isPlaying: Bool = self.audioPlayer.isPlaying

            self.isPlayingPublisher.send(isPlaying)

            if self.audioPlayer.currentTime == self.audioPlayer.duration {
                Task {
                    self.stop()
                }
            }
        }

        do {
            try self.audioPlayer.load(url: url)
            self.audioPlayer.play()
            self.audioPlayer.isLooping = false
            
            self.isPlayingPublisher.send(true)
        } catch {
            stop()
            throw error
        }
    }

    func stop() {
        self.audioPlayer.stop()

        self.isPlayingPublisherTimer?.cancel()
        self.isPlayingPublisherTimer = nil

        AudioConductor.shared.removeOutput(audioPlayer)
        AudioConductor.shared.stop()
        try? AudioConductor.shared.setAudioMode(nil)

        self.isPlayingPublisher.send(false)
    }
}
