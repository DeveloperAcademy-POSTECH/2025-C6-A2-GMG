//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import AVFoundation
import Accelerate
import SwiftUI

enum AudioLevelMeterError: Error {
    case failedToCreateBuffer
}

enum AudioLevelMeter {
    nonisolated static func calculateLevel(from fileURL: URL, windowPerSeconds: TimeInterval = 0.1)
        throws -> [Float]
    {
        let file: AVAudioFile = try AVAudioFile(forReading: fileURL)

        let format: AVAudioFormat = file.processingFormat
        let sampleRate: Double = format.sampleRate

        let framesPerWindow: AVAudioFrameCount = AVAudioFrameCount(sampleRate * windowPerSeconds)

        let levels: [Float] = try calculateLevel(from: file, framesPerWindow: framesPerWindow)

        return levels
    }

    nonisolated static func calculateLevel(from fileURL: URL, framesPerWindow: AVAudioFrameCount)
        throws -> [Float]
    {
        let file: AVAudioFile = try AVAudioFile(forReading: fileURL)

        let levels: [Float] = try calculateLevel(from: file, framesPerWindow: framesPerWindow)

        return levels
    }

    private nonisolated static func calculateLevel(
        from file: AVAudioFile, framesPerWindow: AVAudioFrameCount
    ) throws -> [Float] {
        let format: AVAudioFormat = file.processingFormat
        let channelCount: Int = Int(format.channelCount)
        let totalFrames: AVAudioFramePosition = file.length

        guard framesPerWindow > 0 else {
            return []
        }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: framesPerWindow)
        else {
            throw AudioLevelMeterError.failedToCreateBuffer
        }

        var rms: [Float] = []
        var currentFramePosition: AVAudioFramePosition = .zero

        while currentFramePosition < totalFrames {
            let framesRemaining: AVAudioFrameCount = AVAudioFrameCount(
                totalFrames - currentFramePosition)
            let framesToRead: AVAudioFrameCount = min(framesPerWindow, framesRemaining)

            try file.read(into: buffer, frameCount: framesToRead)

            // 채널별 RMS 계산
            if let channelData = buffer.floatChannelData {
                let frameLength: Int = Int(buffer.frameLength)
                let stride: Int = Int(buffer.stride)
                var channelRMS: [Float] = []

                for channel in 0..<channelCount {
                    let pointer: UnsafeMutablePointer<Float> = channelData[channel]
                    var rms: Float = .zero
                    vDSP_rmsqv(pointer, vDSP_Stride(stride), &rms, vDSP_Length(frameLength))
                    channelRMS.append(rms)
                }

                let avgRMS: Float = channelRMS.reduce(0, +) / Float(channelRMS.count)
                rms.append(avgRMS)
            } else {
                break
            }

            currentFramePosition += AVAudioFramePosition(framesToRead)
        }

        let dBs: [Float] = rms.map(decibels)

        let normalizedLevel: [Float] = dBs.map { dB in
            DecibelsNormalizer.normalize(dB)
        }

        return normalizedLevel
    }

    private nonisolated static func decibels(from rms: Float) -> Float {
        return 20 * log10(rms)
    }
}

#Preview {
    @Previewable @State var audioLevels: [Float] = []
    let minHeight: CGFloat = 10
    let maxHeight: CGFloat = 100

    VStack {
        ScrollView(.horizontal) {
            HStack {
                ForEach(Array(audioLevels.enumerated()), id: \.offset) { index, level in
                    Capsule()
                        .frame(
                            width: 3,
                            height: (maxHeight - minHeight) * CGFloat(level) + minHeight
                        )
                }
            }
            .frame(minHeight: maxHeight)
        }
        .safeAreaPadding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))

        Button("Meter") {
            do {
                guard let url = Bundle.main.url(forResource: "Sample", withExtension: "m4a") else {
                    Logger.debug("Failed to find audio file")
                    return
                }

                let levels = try AudioLevelMeter.calculateLevel(from: url)

                audioLevels = levels
            } catch {
                Logger.error(String(describing: error))
            }
        }
        .buttonStyle(.borderedProminent)
    }
    .padding()
}
