//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

struct BPMSettingModel: Equatable {
    let bpm: Int
    let step: Int // BPM 증가 단위
    let tapTimestamps: [TimeInterval] // tap으로 bpm 설정 시 평균 낼 최근 tap interval
    let maxTapHistory: Int = 5 // 최근 5번의 Tap의 평균을 내서 bpm으로 설정
    
    let minBPM: Int = 40
    let maxBPM: Int = 400
    
    var isValid: Bool { bpm >= minBPM && bpm <= maxBPM }
    
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
        bpm: Int? = nil,
        step: Int? = nil,
        tapTimestamps: [TimeInterval]? = nil
    ) -> BPMSettingModel {
        BPMSettingModel(
            bpm: bpm ?? self.bpm,
            step: step ?? self.step,
            tapTimestamps: tapTimestamps ?? self.tapTimestamps
        )
    }
    
    static let initial = BPMSettingModel(
            bpm: 100,
            step: 1,
            tapTimestamps: []
    )
}
