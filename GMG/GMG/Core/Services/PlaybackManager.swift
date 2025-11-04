//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import AudioKit
import Combine
import Foundation

@Observable
final class PlaybackManager {
    private var audioPlayer: AudioPlayer
    
    private(set) var isPlayingPublisher: CurrentValueSubject<Bool, Never>

    init() {
        self.audioPlayer = AudioPlayer()

        self.isPlayingPublisher = CurrentValueSubject<Bool, Never>(false)
        
        self.audioPlayer.completionHandler = { [weak self] in
            guard let self else { return }
            self.stop()
        }
    }

    func play(_ url: URL) throws {
        try AudioConductor.shared.setAudioMode(.playback)
        AudioConductor.shared.addOutput(audioPlayer)
        try AudioConductor.shared.start()

        try self.audioPlayer.load(url: url)
        self.audioPlayer.play()
        self.audioPlayer.isLooping = false
        
        self.isPlayingPublisher.send(true)
    }

    func stop() {
        self.audioPlayer.stop()

        AudioConductor.shared.stop()
        AudioConductor.shared.removeOutput(audioPlayer)
        try? AudioConductor.shared.setAudioMode(nil)
        
        self.isPlayingPublisher.send(false)
    }
}
