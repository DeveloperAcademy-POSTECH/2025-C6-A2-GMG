//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct RecordingView: View {
    @State private var container: RecordingContainer

    private var state: RecordingState { container.state }

    init(container: RecordingContainer = RecordingContainer()) {
        self._container = State(wrappedValue: container)
    }

    var body: some View {
        ZStack {
            Color.backgroundLight1
                .ignoresSafeArea()

            VStack {
                Metronome()

                Spacer()
            }
            .padding(.top, 80)

            AudioVisualizer(frequencies: state.frequencies)

            VStack {
                Spacer()

                RecordingController(
                    elapsedTime: state.elapsedTime,
                    isRecording: state.isRecording,
                    startRecord: { container.send(.startRecord) },
                    stopRecord: { container.send(.stopRecord) },
                    retakeRecord: { container.send(.retakeRecord) }
                )
            }
            .padding(.bottom, 40)
        }
    }

    struct RecordingController: View {
        let elapsedTime: TimeInterval
        let isRecording: Bool
        let startRecord: () -> Void
        let stopRecord: () -> Void
        let retakeRecord: () -> Void

        var body: some View {
            VStack(spacing: Spacing.lg) {
                RecordingTimer(elapsedTime: elapsedTime)
                RecordButton(
                    isRecording: isRecording,
                    startRecord: startRecord,
                    stopRecord: stopRecord
                )
                RetakeButton(retakeRecord: retakeRecord)
            }
        }
    }

    // TODO: - 컴포넌트 교체 필요
    struct Metronome: View {
        var body: some View {
            HStack(spacing: Spacing.lg) {
                ForEach(0..<4) { _ in
                    Circle()
                        .strokeBorder(.text1, lineWidth: 2)
                        .frame(width: 44, height: 44)
                }
            }
        }
    }

    struct AudioVisualizer: View {
        let frequencies: [Float]

        private let chunkCount: Int = 14

        private let minHeight: CGFloat = 36.0
        private let maxHeight: CGFloat = 80.0

        var body: some View {
            HStack(spacing: 8) {
                let filteredFrequencies =
                    frequencies.count > 128
                    ? Array(frequencies[128..<frequencies.count]) : frequencies
                let seperatedFrequencies = seperateChunk(
                    filteredFrequencies,
                    chunkCount: chunkCount
                )

                ForEach(0..<chunkCount, id: \.self) { index in
                    let height =
                        seperatedFrequencies.indices.contains(index)
                        ? CGFloat(seperatedFrequencies[index])
                            * (maxHeight - minHeight)
                            + minHeight : minHeight

                    Capsule()
                        .fill(.green4)
                        .frame(width: 8, height: height)
                }
            }
            .animation(.default, value: frequencies)
        }

        private func seperateChunk(_ array: [Float], chunkCount: Int) -> [Float]
        {
            let chunkSize = Float(array.count) / Float(chunkCount)

            var seperatedArray: [Float] = []

            for i in 0..<chunkCount {
                let start = Int(round(Float(i) * chunkSize))
                let end = Int(round(Float(i + 1) * chunkSize))

                if start < end {
                    let chunk = array[start..<end]
                    seperatedArray.append(chunk.max() ?? 0.0)
                }
            }

            return seperatedArray
        }
    }

    struct RecordingTimer: View {
        let elapsedTime: TimeInterval

        var body: some View {
            Text(
                "\(hour, specifier: "%02d"):\(minute, specifier: "%02d"):\(second, specifier: "%02d")"
            )
            .font(Typography.DOSGothic.M9)
            .foregroundStyle(.gray6)
        }

        private var hour: Int {
            Int(elapsedTime / 60 / 60)
        }

        private var minute: Int {
            Int((elapsedTime / 60).truncatingRemainder(dividingBy: 60))
        }

        private var second: Int {
            Int(elapsedTime.truncatingRemainder(dividingBy: 60))
        }
    }

    struct RecordButton: View {
        let isRecording: Bool
        let startRecord: () -> Void
        let stopRecord: () -> Void

        var body: some View {
            if isRecording {
                Button {
                    stopRecord()
                } label: {
                    Text("정지하기")
                        .font(Typography.NeoDonggeunmoPro.R6)
                        .foregroundStyle(.text1)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.gray1)
                                .strokeBorder(.black.opacity(0.1))
                        }
                }
            } else {
                Button {
                    startRecord()
                } label: {
                    Text("녹음하기")
                        .font(Typography.NeoDonggeunmoPro.R6)
                        .foregroundStyle(.text1)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.green3)
                                .strokeBorder(.black.opacity(0.1))
                        }
                }
            }
        }
    }

    struct RetakeButton: View {
        let retakeRecord: () -> Void

        var body: some View {
            Button {
                retakeRecord()
            } label: {
                Text("재녹음")
                    .font(Typography.NeoDonggeunmoPro.R6)
                    .foregroundStyle(.text1)
            }
        }
    }
}

#Preview {
    RecordingView()
}
