//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import AVFoundation

enum WaveformError: Error {
    case noAudioTrack
    case readerFailed(String)
}

enum DownsampleMode { case rms, peak }

struct WaveformExtractor {
    
    //MARK: 진폭 배열 추출 함수 (녹음본 다운샘플링)
    static func extractAmplitudes(from url: URL, bins: Int, mode: DownsampleMode = .rms, targetSampleRate: Double = 44_100) async throws -> [Float] {
        let asset = AVURLAsset(url: url)
        
        //Track 로딩
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard let track = audioTracks.first else {
            throw WaveformError.noAudioTrack
        }
        
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMBitDepthKey: 32,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: targetSampleRate
        ])
        
        output.alwaysCopiesSampleData = false
        reader.add(output)
        
        guard reader.startReading() else {
            throw WaveformError.readerFailed(reader.error?.localizedDescription ?? "Unknown Error")
        }
        
        let duration = try await asset.load(.duration)
        let durationSec = duration.seconds
        let totalSamplesEstimate = max(1, Int(durationSec * targetSampleRate))
        let samplePerBin = max(1, totalSamplesEstimate / max(1, bins))
        
        var binAmplitudes = [Float](); binAmplitudes.reserveCapacity(bins)
        var sampleCountInBin = 0 //현재 Bin에 몇 개의 샘플이 쌓였는지
        var sumOfSquaredSamples: Float = 0 //RMS 계산을 위한 샘플^2 누적값
        var peakAmplitudeInBin: Float = 0 //현재 bin에서 가장 큰 진폭 (피크값)
        
        // 현재 bin에 들어갈 샘플을 누적하다가 samplePerBin 개가 쌓이면 emitBin()으로 해당 bin의 대표값(RMS 또는 피크)을 확정하고 초기화
        func emitBin() {
            guard sampleCountInBin > 0 else { return }
            let binValue: Float = (mode == .rms)
                ? sqrt(sumOfSquaredSamples / Float(sampleCountInBin))
                : peakAmplitudeInBin
            binAmplitudes.append(binValue)
            sampleCountInBin = 0; sumOfSquaredSamples = 0; peakAmplitudeInBin = 0
        }
        
        while reader.status == .reading {
            guard let sampleBuffer = output.copyNextSampleBuffer() else { break }
            guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
                CMSampleBufferInvalidate(sampleBuffer)
                continue
            }
            
            var byteLength = 0
            var pointer: UnsafeMutablePointer<Int8>?
            CMBlockBufferGetDataPointer(
                dataBuffer, atOffset: 0,
                lengthAtOffsetOut: nil,
                totalLengthOut: &byteLength,
                dataPointerOut: &pointer
            )
            
            if let pointer {
                let sampleCount = byteLength / MemoryLayout<Float>.size
                pointer.withMemoryRebound(to: Float.self, capacity: sampleCount) { floatPointer in
                    var index = 0
                    while index < sampleCount {
                        let sample = floatPointer[index]
                        let amplitude = abs(sample)
                        
                        peakAmplitudeInBin = max(peakAmplitudeInBin, amplitude)
                        sumOfSquaredSamples += sample * sample
                        sampleCountInBin += 1
                        
                        if sampleCountInBin >= samplePerBin {
                            emitBin()
                        }
                        index += 1
                    }
                }
            }
            CMSampleBufferInvalidate(sampleBuffer)
        }
        if sampleCountInBin > 0 { emitBin() }
        
        if binAmplitudes.count < bins { binAmplitudes.append(contentsOf: Array(repeating: 0, count: bins - binAmplitudes.count)) }
        if binAmplitudes.count > bins { binAmplitudes.removeLast(binAmplitudes.count - bins) }
        
        if reader.status == .failed {
            throw WaveformError.readerFailed(reader.error?.localizedDescription ?? "Unknown error")
        }
        
        let PeakForNormalization = max(binAmplitudes.max() ?? 0, 1e-6) //1e-6은 최솟값으로, 완전 무음이어서 mx가 0일때 0으로 나누면 크래시가 나기 때문에 최솟값을 보장하기 위해 사용 (엡실론)
        let waveform = binAmplitudes.map { min(1, max(0, $0 / PeakForNormalization)) }
        
        return waveform
    }
}
