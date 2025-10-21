//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

protocol BPMSettingModelProtocol {
    var bpm: Int { get }
    var step: Int { get }
    
    var tapTimestamps: [TimeInterval] { get }
    var maxTapHistory: Int { get }
    
    var isLongPressed: Bool { get }
    var longPressStep: Int { get }
    var shortPressStep: Int { get }
    
    var minBPM: Int { get }
    var maxBPM: Int { get }
    
    var isValid: Bool { get }
    var computedBPMFromTaps: Int? { get }
}
