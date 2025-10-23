//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

protocol TimeSignatureSettingStateProtocol {
    var bpm: BPM { get }
    var timeSignature: TimeSignature { get }
    var isPlaying: Bool { get }
}

protocol TimeSignatureSettingActionProtocol: AnyObject {
    func setTimeSignature(_ value: TimeSignature)
}
