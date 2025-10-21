//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

enum BPMSettingIntent {
    case tapPlus
    case tapMinus
    
    case longPressPlusStart
    case longPressPlusTick
    case longPressPlusEnd
    
    case longPressMinusStart
    case longPressMinusTick
    case longPressMinusEnd
    
    case changePressState
    case longPressIncrease
    
    case tapBeat (now: TimeInterval)
    case resetTap
    case commitTapBPM
    
    case setBPM (Int)
    case setStep (Int)
}
