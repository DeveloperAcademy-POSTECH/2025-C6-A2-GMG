//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

final class TimeSignatureSettingModel: TimeSignatureSettingStateProtocol, TimeSignatureSettingActionProtocol {
    private(set) var bpm: BPM
    private(set) var timeSignature: TimeSignature
    private(set) var isPlaying: Bool
    
    init(timeSignature: TimeSignature, bpm: BPM) {
        self.bpm = bpm
        self.timeSignature = timeSignature
        isPlaying = true
    }
    
    func setTimeSignature(_ value: TimeSignature) {
        timeSignature = value
    }
}
