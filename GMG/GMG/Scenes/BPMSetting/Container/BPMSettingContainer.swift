//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import Combine

final class BPMSettingContainer: ObservableObject, BPMSettingIntentProtocol {
    @Published private(set) var state: BPMSettingModel
    
    init() {
        self.state = .initial
    }
    
    func tapPlus() {
        let next = state.bpm.value + state.shortPressStep
        state = state.copy(bpm: BPM(value: next > state.maxBPM ? state.maxBPM : next))
    }
    
    func tapMinus() {
        let next = state.bpm.value - state.shortPressStep
        state = state.copy(bpm: BPM(value: next < state.minBPM ? state.minBPM : next))
    }
    func longPressPlusStart() {}
    func longPressPlusTick() {}
    func longPressPlusEnd() {}
    
    func longPressMinusStart() {}
    func longPressMinusTick() {}
    func longPressMinusEnd() {}
    
    func tapBeat(now: TimeInterval) {
        var ts = state.tapTimestamps
        ts.append(now)
        if ts.count > state.maxTapHistory {
            ts = Array(ts.suffix(state.maxTapHistory))
        }
        state = state.copy(tapTimestamps: ts)
    }
    
    func resetTap() {
        state = state.copy(tapTimestamps: [])
    }
    
    func commitTapBPM() {
        guard let tapBPM = state.computedBPMFromTaps else { return }
        
        var clamped = tapBPM
        
        if clamped < state.minBPM { clamped = state.minBPM }
        if clamped > state.maxBPM { clamped = state.maxBPM }
        
        guard abs(state.bpm.value - clamped) > 1 else { return }
        
        state = state.copy(bpm: BPM(value: clamped))
    }
}
