//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

enum BPMSettingIntent {
    case tapPlus
    case tapMinus
    
    case longPressPlusStart
    case longPressPlusEnd
    
    case longPressMinusStart
    case longPressMinusEnd
    
    case tapBeat (now: TimeInterval)
    case resetTap
    case commitTapBPM
}
