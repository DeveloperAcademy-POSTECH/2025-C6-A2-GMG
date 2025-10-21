//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

protocol BPMSettingIntentProtocol: AnyObject {
    func tapPlus()
    func tapMinus()
    
    func longPressPlusStart()
    func longPressPlusTick()
    func longPressPlusEnd()
    
    func longPressMinusStart()
    func longPressMinusTick()
    func longPressMinusEnd()
    
    func tapBeat (now: TimeInterval)
    func resetTap()
    func commitTapBPM()
}
