//  Copyright © 2025 ADA 4th GMG. All rights reserved.
import SwiftUI

struct Waveform: View {
    @Environment(\.editMode) private var editMode

    let width: CGFloat
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

    private var capsuleCount: Int {
        let contentWidth = max(0, width - (horizontalPadding * 2))
        let unit = capsuleWidth + capsuleSpacing
        guard unit > 0 else { return max(1, amplitudes.count) }

        let count = Int(floor((contentWidth + capsuleSpacing) / unit))

        return max(1, count)
    }

    private var preparedAmplitudes: [Float] {
        guard capsuleCount > 0 else { return [] }

        if amplitudes.isEmpty {
            return Array(repeating: 0.0, count: capsuleCount)
        }

        if amplitudes.count == capsuleCount {
            return amplitudes
        } else if amplitudes.count > capsuleCount {
            return resample(amplitudes, to: capsuleCount)
        } else {
            return resample(amplitudes, to: capsuleCount)
        }
    }

    private var progressWidth: CGFloat {
        guard endTime > startTime else { return 0 }

        let clampedElapsed = min(max(elapsedTime, startTime), endTime)
        let ratio = (clampedElapsed - startTime) / (endTime - startTime)

        return width * CGFloat(ratio)
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

            let interpolationFactor = scaled - Float(lower)
            return source[lower] * (1 - interpolationFactor) + source[upper] * interpolationFactor
        }
    }

    var body: some View {
        HStack {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)

                CapsuleStack(
                    amplitudes: preparedAmplitudes,
                    color: unFilledCapsuleColor,
                    capsuleWidth: capsuleWidth,
                    capsuleSpacing: capsuleSpacing,
                    horizontalPadding: horizontalPadding,
                    minCapsuleHeight: minCapsuleHeight,
                    maxCapsuleHeight: maxCapsuleHeight
                )

                CapsuleStack(
                    amplitudes: preparedAmplitudes,
                    color: filledCapsuleColor,
                    capsuleWidth: capsuleWidth,
                    capsuleSpacing: capsuleSpacing,
                    horizontalPadding: horizontalPadding,
                    minCapsuleHeight: minCapsuleHeight,
                    maxCapsuleHeight: maxCapsuleHeight
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
            .frame(width: width)

            Spacer()
        }
    }
}

extension Waveform {
    struct CapsuleStack: View {
        let amplitudes: [Float]
        let color: Color

        let capsuleWidth: CGFloat
        let capsuleSpacing: CGFloat
        let horizontalPadding: CGFloat
        let minCapsuleHeight: CGFloat
        let maxCapsuleHeight: CGFloat

        init(
            amplitudes: [Float],
            color: Color,
            capsuleWidth: CGFloat,
            capsuleSpacing: CGFloat,
            horizontalPadding: CGFloat,
            minCapsuleHeight: CGFloat,
            maxCapsuleHeight: CGFloat
        ) {
            self.amplitudes = amplitudes
            self.color = color
            self.capsuleWidth = capsuleWidth
            self.capsuleSpacing = capsuleSpacing
            self.horizontalPadding = horizontalPadding
            self.minCapsuleHeight = minCapsuleHeight
            self.maxCapsuleHeight = maxCapsuleHeight
        }

        private func capsuleHeight(for amplitude: Float) -> CGFloat {
            let clamped = max(0, min(1, amplitude))
            let range = maxCapsuleHeight - minCapsuleHeight
            return minCapsuleHeight + range * CGFloat(clamped)
        }

        var body: some View {
            HStack(alignment: .center, spacing: capsuleSpacing) {
                ForEach(Array(amplitudes.enumerated()), id: \.offset) { (index, amplitude) in
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
    }
}
