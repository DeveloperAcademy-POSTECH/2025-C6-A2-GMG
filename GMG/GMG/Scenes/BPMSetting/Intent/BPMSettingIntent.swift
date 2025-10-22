//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

final class BPMSettingIntent: BPMSettingIntentProtocol {
    weak var model: (any BPMSettingActionProtocol)?

    init(model: (any BPMSettingActionProtocol)? = nil) {
        self.model = model
    }

    func setBPM(_ value: Int) {
        model?.setBPM(value)
    }
    
    func tapPlus() {
        model?.tapPlus(step: 1)
    }
    
    func tapMinus() {
        model?.tapMinus(step: 1)
    }
    
    func tapBeat() {
        model?.tapBeat(at: Date().timeIntervalSince1970)
    }
    
    func startLongPress() {
        model?.setLongPressed(true)
    }
    
    func stopLongPress() {
        model?.setLongPressed(false)
    }
    
    func tickWhileLongPressing() {
        model?.longPressTick()
    }
}
