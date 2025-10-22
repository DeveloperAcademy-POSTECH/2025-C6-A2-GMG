//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

struct BPMSettingModel: Equatable {
    let bpm: BPM
    let tapTimestamps: [TimeInterval] // tap으로 bpm 설정 시 평균 낼 최근 tap interval
    let maxTapHistory: Int = 5 // 최근 5번의 Tap의 평균을 내서 bpm으로 설정
    
    let isLongPressed: Bool
    let longPressStep: Int
    let shortPressStep: Int
    
    let minBPM: Int = 10
    let maxBPM: Int = 400
    
    var isValid: Bool { bpm.value >= minBPM && bpm.value <= maxBPM }
    
    var computedBPMFromTaps: Int? {
        guard tapTimestamps.count >= 2 else { return nil }
        
        let timestamps = tapTimestamps
        var intervals: [TimeInterval] = []

        for i in 1..<timestamps.count {
            let interval = timestamps[i] - timestamps[i - 1]
            intervals.append(interval)
        }

        guard !intervals.isEmpty else { return nil }

        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        let bpm = Int((60.0 / averageInterval).rounded())
        return bpm
    }
}

extension BPMSettingModel {
    func copy(
        bpm: BPM? = nil,
        tapTimestamps: [TimeInterval]? = nil,
        isLongPressed: Bool? = nil,
        longPressStep: Int? = nil,
        shortPressStep: Int? = nil
    ) -> BPMSettingModel {
        BPMSettingModel(
            bpm: bpm ?? self.bpm,
            tapTimestamps: tapTimestamps ?? self.tapTimestamps,
            isLongPressed: isLongPressed ?? self.isLongPressed,
            longPressStep: longPressStep ?? self.longPressStep,
            shortPressStep: shortPressStep ?? self.shortPressStep
        )
    }
    
    static let initial = BPMSettingModel(
            bpm: BPM(value: 100),
            tapTimestamps: [],
            isLongPressed: false,
            longPressStep: 10,
            shortPressStep: 1
    )
}

extension BPMSettingModel: BPMSettingModelProtocol {}
