//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

protocol BPMSettingIntentProtocol {
    func setBPM(_ value: Int)
    func tapPlus()
    func tapMinus()
    func tapBeat()
    func startLongPress()
    func stopLongPress()
    func tickWhileLongPressing()
}
