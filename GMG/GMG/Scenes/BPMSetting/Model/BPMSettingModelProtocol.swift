//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

protocol BPMSettingStateProtocol {
    var bpm: BPM { get }
    var sliderValue: Double { get }
    var isValid: Bool { get }
}

protocol BPMSettingActionProtocol: AnyObject {
    func setBPM(_ value: Int)
    func tapPlus(step: Int)
    func tapMinus(step: Int)
    func tapBeat(at time: TimeInterval)
    func setLongPressed(_ isOn: Bool)
    func longPressTick()
}
