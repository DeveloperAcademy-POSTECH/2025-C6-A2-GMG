//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import Combine

final class BPMSettingContainer: ObservableObject, BPMSettingIntentProtocol {
    @Published private(set) var state: BPMSettingModel
    
    private var armTimer: Timer?
    private var repeatTimer: Timer?
    
    private enum LongPressTarget { case plus, minus }
    
    private let longPressChangeTime: TimeInterval = 1.0
    private let longPressRepeatTime: TimeInterval = 0.1
    
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
    
    func longPressPlusStart() {
        startArmTimer(target: .plus)
    }
    
    func longPressPlusEnd() {
        initTimers()
    }
    
    func longPressMinusStart() {
        startArmTimer(target: .minus)
    }
    
    func longPressMinusEnd() {
        initTimers()
    }
    
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
    
    private func initTimers() {
        armTimer?.invalidate()
        armTimer = nil
        
        repeatTimer?.invalidate()
        repeatTimer = nil
    }
    
    private func startRepeatTimer(target: LongPressTarget) {
        repeatTimer?.invalidate()
        repeatTimer = Timer.scheduledTimer(withTimeInterval: longPressRepeatTime, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            
            var next: Int
            
            switch target {
            case .plus:
                next = self.state.bpm.value + self.state.longPressStep
            case .minus:
                next = self.state.bpm.value - self.state.longPressStep
            }
            let clamped = min(max(next, self.state.minBPM), self.state.maxBPM)
            self.state = self.state.copy(bpm: BPM(value: clamped))
        })
        RunLoop.main.add(repeatTimer!, forMode: .common)
    }
    
    private func startArmTimer(target: LongPressTarget) {
        initTimers()
        armTimer = Timer.scheduledTimer(withTimeInterval: longPressChangeTime, repeats: false, block: { [weak self]_ in
            self?.startRepeatTimer(target: target)
        })
        RunLoop.main.add(armTimer!, forMode: .common)
    }
    deinit {
        initTimers()
    }
}
