//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

@Observable
final class BPMSettingModel: BPMSettingStateProtocol, BPMSettingActionProtocol {
    private(set) var bpm: BPM = BPM(value: 100) //현재 저장된 BPM값
    private(set) var tapTimestamps: [TimeInterval] = [] // tap으로 bpm 설정 시 평균 낼 최근 tap interval
    private let maxTapHistory: Int = 5 // 최근 5번의 Tap의 평균을 내서 bpm으로 설정
    
    private var isLongPressed: Bool = false // 길게 눌렸나 추적
    private let longPressStep: Int = 10 // 길게 눌렀을 때 올라갈 bpm 숫자
    private let shortPressStep: Int = 1 // 짧게 눌렀을 때 올라갈 bpm 숫자
    
    private let minBPM: Int = 10 //최소 BPM
    private let maxBPM: Int = 400 //최대 BPM
    
    private(set) var bpmText: String = "100"
    private(set) var sliderValue: Double = 0.0
    
    // bpm값이 min & max 안에 있는지 확인
    var isValid: Bool { bpm.value >= minBPM && bpm.value <= maxBPM }
    
    // bpm 값이 정해진 기준 초과/미만일 경우 최대/최솟값으로 지정
    private func clamped(_ bpm: BPM) -> BPM {
        .init(value: max(minBPM, min(maxBPM, bpm.value)))
    }
    
    private func appendTap(_ timestamp: TimeInterval) -> Void {
        let new = (tapTimestamps + [timestamp]).suffix(maxTapHistory)
        tapTimestamps = Array(new)
    }
    
    //intervals에 클릭한 간격 삽입
    private var computedBPMFromTaps: Int? {
        guard tapTimestamps.count >= 2 else { return nil }
        var intervals: [TimeInterval] = []

        for i in 1..<tapTimestamps.count {
            intervals.append(tapTimestamps[i] - tapTimestamps[i - 1])
        }

        guard !intervals.isEmpty else { return nil }
        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        return Int((60.0 / averageInterval).rounded()) // BPM 변환 공식 (+ 반올림)
    }
    
    private func syncDerived() {
        bpmText = "\(bpm.value)"
        let denom = max(1, maxBPM - minBPM)
        sliderValue = Double(bpm.value - minBPM) / Double(denom)
    }
    
    func setBPM(_ value: Int) {
        bpm = clamped(BPM(value: value))
    }
    
    func tapPlus(step: Int) {
        setBPM(bpm.value + step)
    }
    
    func tapMinus(step: Int) {
        setBPM(bpm.value - step)
    }
    
    func tapBeat(at time: TimeInterval) {
        appendTap(time)
        if let computed = computedBPMFromTaps {
            setBPM(computed)
        } else {
            syncDerived()
        }
    }
    
    func setLongPressed(_ isOn: Bool) {
        isLongPressed = isOn
        syncDerived()
    }
    
    func longPressTick() {
        guard isLongPressed else { return }
        setBPM(bpm.value + longPressStep)
    }
}
