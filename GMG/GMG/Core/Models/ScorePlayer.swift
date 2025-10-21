//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Combine

class ScorePlayer {
    private var playhead: Playhead {
        didSet {
            playheadPublisher.send(playhead)
        }
    }
    let playheadPublisher: PassthroughSubject<Playhead, Never> =
        PassthroughSubject<Playhead, Never>()

    init() {
        self.playhead = Playhead(
            isPlaying: false,
            currentMeasureIndex: 0,
            currentCellIndex: 0,
            elapsedDuration: 0.0
        )
    }

    func play() {

    }

    func pause() {

    }

    func stop() {

    }

    func seek(measureIndex: Int, cellIndex: Int) {

    }

    func play(chord: Chord) {

    }
}
