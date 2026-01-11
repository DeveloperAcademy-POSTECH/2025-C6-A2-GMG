//  Copyright © 2025 ADA 4th GMG. All rights reserved.
import SwiftUI

struct Waveform: View {
    @Environment(\.editMode) private var editMode
    @Environment(\.palette) private var palette

    let width: CGFloat
    let amplitudes: [Float]
    let startTime: TimeInterval
    let endTime: TimeInterval
    let elapsedTime: TimeInterval
    let onTap: (TimeInterval) -> Void
    let onDragStart: (TimeInterval) -> Void
    let onDragChange: (TimeInterval) -> Void
    let onDragEnd: (TimeInterval) -> Void

    @State private var draggingTime: TimeInterval?

    private let capsuleWidth: CGFloat = 3
    private let capsuleSpacing: CGFloat = 5
    private let horizontalPadding: CGFloat = 15
    private let minCapsuleHeight: CGFloat = 4
    private let maxCapsuleHeight: CGFloat = 15
    private var capsuleUnitWidth: CGFloat {
        capsuleWidth + capsuleSpacing
    }

    private var backgroundColor: Color {
        if editMode?.wrappedValue.isEditing == true {
            palette.waveformBackgroundEdit
        } else {
            palette.waveformBackgroundView
        }
    }

    private var unFilledCapsuleColor: Color {
        if editMode?.wrappedValue.isEditing == true {
            palette.waveformUnfilledEdit
        } else {
            palette.waveformUnfilledView
        }
    }

    private var filledCapsuleColor: Color {
        if editMode?.wrappedValue.isEditing == true {
            palette.waveformFilledEdit
        } else {
            palette.waveformFilledView
        }
    }

    private var capsuleCount: Int {
        let widthWithoutPadding = max(0, width - (horizontalPadding * 2))

        let count = Int(floor((widthWithoutPadding + capsuleSpacing) / capsuleUnitWidth))

        return count
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

        var lastInteractionTime = elapsedTime

        if let draggingTime = self.draggingTime {
            lastInteractionTime = draggingTime
        }

        let clampedElapsed = min(max(lastInteractionTime, startTime), endTime)
        let ratio = (clampedElapsed - startTime) / (endTime - startTime)

        return width * CGFloat(ratio)
    }

    private func resample(_ source: [Float], to targetCount: Int) -> [Float] {
        guard targetCount > 1, source.count > 1 else {
            let value = source.first ?? 0
            return Array(repeating: value, count: targetCount)
        }

        let maxIndex = max(1, targetCount - 1)

        return (0..<targetCount).map { index in
            let position = (Float(index)) / Float(maxIndex)
            let normalizedPosition = min(max(position, 0), 1)
            let scaled = normalizedPosition * Float(source.count - 1)
            let lower = Int(floor(scaled))
            let upper = Int(ceil(scaled))

            if lower == upper {
                return source[lower]
            }

            let interpolationFactor = scaled - Float(lower)
            return source[lower] * (1 - interpolationFactor) + source[upper] * interpolationFactor
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                let time = convertLocationToTime(value.location.x)

                if draggingTime == nil {
                    onDragStart(time)
                } else {
                    onDragChange(time)
                }

                draggingTime = time
            }
            .onEnded { value in
                let time = convertLocationToTime(value.location.x)
                draggingTime = nil
                onDragEnd(time)
            }
    }

    private func convertLocationToTime(_ locationX: CGFloat) -> TimeInterval {
        guard width > 0 else { return startTime }

        let clampedX = min(max(locationX, 0), width)
        let ratio = clampedX / width
        return startTime + ((endTime - startTime) * TimeInterval(ratio))
    }

    var body: some View {
        HStack {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
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
                        RoundedRectangle(cornerRadius: 8)
                            .frame(width: progressWidth)
                        Spacer(minLength: 0)
                    }
                )
            }
            .frame(width: width)
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .onTapGesture { location in
                let tappedTime = convertLocationToTime(location.x)
                onTap(tappedTime)
            }

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
                    RoundedRectangle(cornerRadius: 6)
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
