//  Copyright © 2025 ADA 4th GMG. All rights reserved.
import SwiftUI

struct Waveform: View {
    @Environment(\.editMode) private var editMode
    
    let amplitudes: [Float]
    let startTime: TimeInterval
    let endTime: TimeInterval
    let elapsedTime: TimeInterval
    
    private let capsuleWidth: CGFloat = 3
    private let capsuleSpacing: CGFloat = 4
    private let horizontalPadding: CGFloat = 11
    private let minCapsuleHeight: CGFloat = 6
    private let maxCapsuleHeight: CGFloat = 21
    
    private var backgroundColor: Color {
        if editMode?.wrappedValue.isEditing == true {
            Color.black2
        } else {
            Color.white2
        }
    }
    
    private var unFilledCapsuleColor: Color {
        if editMode?.wrappedValue.isEditing == true {
            Color.black7
        } else {
            Color.white3
        }
    }
    
    private var filledCapsuleColor: Color {
        if editMode?.wrappedValue.isEditing == true {
            Color.white1
        } else {
            Color.blue4
        }
    }
    
    var body: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width * ((endTime - startTime) / 5)
            let capsuleCount = capsuleCount(for: totalWidth)
            let preparedAmplitudes = amplitudesForRendering(targetCount: capsuleCount)
            let progressWidth = fillWidth(totalWidth: totalWidth)
            
            ZStack(alignment: .leading) {
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                
                CapsuleStack(
                    amplitudes: preparedAmplitudes,
                    color: unFilledCapsuleColor
                )
                
                CapsuleStack(
                    amplitudes: preparedAmplitudes,
                    color: filledCapsuleColor
                )
                .mask(
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 12)
                            .frame(width: progressWidth)
                        Spacer(minLength: 0)
                    }
                )
                .animation(.easeInOut(duration: 0.25), value: progressWidth)
            }
            .frame(width: totalWidth)
        }
        .frame(height: 35)
    }
    
    struct CapsuleStack: View {
        let amplitudes: [Float]
        let color: Color

        private let capsuleWidth: CGFloat
        private let capsuleSpacing: CGFloat
        private let horizontalPadding: CGFloat
        private let minCapsuleHeight: CGFloat
        private let maxCapsuleHeight: CGFloat
        
        init(
            amplitudes: [Float],
            color: Color,
            capsuleWidth: CGFloat = 3,
            capsuleSpacing: CGFloat = 4,
            horizontalPadding: CGFloat = 11,
            minCapsuleHeight: CGFloat = 6,
            maxCapsuleHeight: CGFloat = 21
        ) {
            self.amplitudes = amplitudes
            self.color = color
            self.capsuleWidth = capsuleWidth
            self.capsuleSpacing = capsuleSpacing
            self.horizontalPadding = horizontalPadding
            self.minCapsuleHeight = minCapsuleHeight
            self.maxCapsuleHeight = maxCapsuleHeight
        }
        
        var body: some View {
            HStack(alignment: .center, spacing: capsuleSpacing) {
                ForEach(amplitudes.indices, id: \.self) { index in
                    let amplitude = amplitudes[index]
                    Capsule()
                        .fill(color)
                        .frame(
                            width: capsuleWidth,
                            height: capsuleHeight(for: amplitude)
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, horizontalPadding)

        }
        
        func capsuleHeight(for amplitude: Float) -> CGFloat {
            let clamped = max(0, min(1, amplitude))
            let range = maxCapsuleHeight - minCapsuleHeight
            return minCapsuleHeight + range * CGFloat(clamped)
        }
    }
    
    private func fillWidth(totalWidth: CGFloat) -> CGFloat {
        guard endTime > startTime else { return 0 }
        let clampedElapsed = min(max(elapsedTime, startTime), endTime)
        let ratio = (clampedElapsed - startTime) / (endTime - startTime)
        return totalWidth * CGFloat(ratio)
    }
    
    private func capsuleCount(for totalWidth: CGFloat) -> Int {
        let contentWidth = max(0, totalWidth - (horizontalPadding * 2))
        let unit = capsuleWidth + capsuleSpacing
        guard unit > 0 else { return max(1, amplitudes.count) }
        
        let count = Int(floor((contentWidth + capsuleSpacing) / unit))
        return max(1, count)
    }
    
    private func amplitudesForRendering(targetCount: Int) -> [Float] {
        guard targetCount > 0 else { return [] }
        
        if amplitudes.isEmpty {
            return Array(repeating: 0.0, count: targetCount)
        }
        
        if amplitudes.count == targetCount {
            return amplitudes
        } else if amplitudes.count > targetCount {
            return resample(amplitudes, to: targetCount)
        } else {
            return resample(amplitudes, to: targetCount)
        }
    }
    
    private func resample(_ source: [Float], to targetCount: Int) -> [Float] {
        guard targetCount > 1, source.count > 1 else {
            let value = source.first ?? 0
            return Array(repeating: value, count: targetCount)
        }
        
        return (0..<targetCount).map { index in
            let position = Float(index) / Float(targetCount - 1)
            let scaled = position * Float(source.count - 1)
            let lower = Int(floor(scaled))
            let upper = Int(ceil(scaled))
            
            if lower == upper {
                return source[lower]
            }
            
            let t = scaled - Float(lower)
            return source[lower] * (1 - t) + source[upper] * t
        }
    }
}
