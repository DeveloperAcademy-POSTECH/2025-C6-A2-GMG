//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

struct RecordingState {
    let isRecording: Bool
    let elapsedTime: TimeInterval
    let frequencies: [Float]
}

extension RecordingState {
    func copy(
        isRecording: Bool? = nil,
        elapsedTime: TimeInterval? = nil,
        frequencies: [Float]? = nil
    ) -> RecordingState {
        return RecordingState(
            isRecording: isRecording ?? self.isRecording,
            elapsedTime: elapsedTime ?? self.elapsedTime,
            frequencies: frequencies ?? self.frequencies,
        )
    }
}

extension RecordingState {
    static var mock: RecordingState {
        RecordingState(
            isRecording: false,
            elapsedTime: 0.0,
            frequencies: [],
        )
    }
}
