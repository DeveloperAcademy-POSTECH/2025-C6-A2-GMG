//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct WaveformView: View {
    let amplitudes: [Float]
    let highlight: Range<Int>?
    var progress: Double = 0.0    // 0.0 ~ 1.0

    var body: some View {
        GeometryReader { geo in
            let barWidth: CGFloat = 5.0
            let barSpacing: CGFloat = 5.0
            let step = barWidth + barSpacing
            let barCount = max(1, Int(geo.size.width / step))
            let amps = resample(amplitudes, to: barCount)
            let amplitudeFloor: CGFloat = 0.0

            // 현재 진행에 따른 마지막 채워질 막대 인덱스
            let filledIndex: Int = {
                let idx = Int(round(progress * Double(max(0, amps.count - 1))))
                return min(max(idx, 0), max(0, amps.count - 1))
            }()

            Canvas { ctx, size in
                // highlight 범위 매핑
                let mappedHL: Range<Int>? = {
                    guard let r = highlight else { return nil }
                    let start = Int(CGFloat(r.lowerBound) / CGFloat(amplitudes.count) * CGFloat(amps.count))
                    let end   = Int(CGFloat(r.upperBound) / CGFloat(amplitudes.count) * CGFloat(amps.count))
                    return start..<min(end, amps.count)
                }()
                
                let minBarHeight: CGFloat = 9
                let maxBarHeight: CGFloat = 19

                for i in 0..<amps.count {
                    var v = CGFloat(amps[i])
                    if v < amplitudeFloor { continue }
                    v = (v - amplitudeFloor) / (1 - amplitudeFloor)

                    let h = minBarHeight + (maxBarHeight - minBarHeight) * v
                    let x = CGFloat(i) * step
                    let y = (size.height - h) / 2
                    let path = Path(roundedRect: CGRect(x: x, y: y, width: barWidth, height: h),
                                    cornerRadius: barWidth / 2)

                    // 색 결정: highlight > filled > 기본
                    let isHL = mappedHL?.contains(i) ?? false
                    let isFilled = i <= filledIndex
                    let color: Color = {
                        if isHL { return .green }
                        if isFilled { return .green }
                        return .gray.opacity(0.35)
                    }()

                    ctx.fill(path, with: .color(color))
                }
            }
        }
        .frame(height: 30)
    }

    private func resample(_ src: [Float], to count: Int) -> [Float] {
        guard !src.isEmpty, count > 0 else { return [] }
        if src.count == count { return src }
        var dst = [Float](repeating: 0, count: count)
        for i in 0..<count {
            let t = Float(i) / Float(max(1, count - 1))
            let idx = Int(round(t * Float(max(0, src.count - 1))))
            dst[i] = src[idx]
        }
        return dst
    }
}
