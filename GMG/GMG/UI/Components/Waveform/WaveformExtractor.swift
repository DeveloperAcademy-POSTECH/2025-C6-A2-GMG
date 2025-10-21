//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import AVFoundation

enum WaveformError: Error {
    case noAudioTrack
    case readerFailed(String)
}

enum DownsampleMode { case rms, peak }

struct WaveformExtractor {
    
    //MARK: 디코딩 파이프가 정상 작동하는 지 샘플 개수 세어서 확인하는 함수 -> 동작에는 크게 필요없지만 debug용으로 작동하는 함수
    static func debugCountSamples(from url: URL, targetSampleRate: Double = 44_100) async throws -> Int {
        let asset = AVURLAsset(url: url)
        
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard let track = audioTracks.first else {
            throw WaveformError.noAudioTrack
        }
        
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMBitDepthKey: 32,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: targetSampleRate
        ]
        
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        output.alwaysCopiesSampleData = false
        reader.add(output)
        
        guard reader.startReading() else {
            throw WaveformError.readerFailed(reader.error?.localizedDescription ?? "Unknown Error")
        }
        
        var totalFloatSamples = 0
        
        while reader.status == .reading {
            guard let sbuf = output.copyNextSampleBuffer() else {
                break
            }
            guard let blockBuffer = CMSampleBufferGetDataBuffer(sbuf) else {
                continue
            }
            
            var length = 0
            var dataPointer: UnsafeMutablePointer<Int8>?
            CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)
            
            if let _ = dataPointer {
                let count = length / MemoryLayout<Float>.size
                
                totalFloatSamples += count
            }
            CMSampleBufferInvalidate(sbuf)
        }
        
        if reader.status == .failed {
            throw WaveformError.readerFailed(reader.error?.localizedDescription ?? "reader Failed")
        }
        
        return totalFloatSamples
    }
    
    //MARK: 진폭 배열 추출 함수 (녹음본 다운샘플링)
    static func extractAmplitudes(from url: URL, bins: Int, mode: DownsampleMode = .rms, targetSampleRate: Double = 44_100) async throws -> [Float] {
        let asset = AVURLAsset(url: url)
        
        //Track 로딩
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard let track = audioTracks.first else {
            throw WaveformError.noAudioTrack
        }
        
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMBitDepthKey: 32,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: targetSampleRate
        ]
        
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        output.alwaysCopiesSampleData = false
        reader.add(output)
        
        guard reader.startReading() else {
            throw WaveformError.readerFailed(reader.error?.localizedDescription ?? "Unknown Error")
        }
        
        let duration = try await asset.load(.duration)
        let durationSec = duration.seconds
        let totalSamplesEstimate = max(1, Int(durationSec * targetSampleRate))
        let samplePerBin = max(1, totalSamplesEstimate / max(1, bins))
        
        // bin 단위로 accCount/accEnergy, accPeak를 모았다가 꽉 차면
        var result = [Float](); result.reserveCapacity(bins)
        var accCount = 0
        var accEnergy: Float = 0
        var accPeak: Float = 0
        
        func flushBin() {
            guard accCount > 0 else { return }
            let v: Float = (mode == .rms)
                ? sqrt(accEnergy / Float(accCount))
                : accPeak
            result.append(v)
            accCount = 0; accEnergy = 0; accPeak = 0
        }
        
        while reader.status == .reading {
            guard let sbuf = output.copyNextSampleBuffer() else { break }
            guard let block = CMSampleBufferGetDataBuffer(sbuf) else {
                CMSampleBufferInvalidate(sbuf)
                continue
            }
            
            var length = 0
            var p: UnsafeMutablePointer<Int8>?
            CMBlockBufferGetDataPointer(block, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &p)
            
            if let p {
                let count = length / MemoryLayout<Float>.size
                p.withMemoryRebound(to: Float.self, capacity: count) { fptr in
                    var i = 0
                    while i < count {
                        let s = fptr[i]
                        let a = abs(s)
                        accPeak = max(accPeak, a)
                        accEnergy += s * s
                        accCount += 1
                        
                        if accCount >= samplePerBin {
                            flushBin()
                        }
                        i += 1
                    }
                }
            }
            CMSampleBufferInvalidate(sbuf)
        }
        if accCount > 0 { flushBin() }
        
        if result.count < bins { result.append(contentsOf: Array(repeating: 0, count: bins - result.count)) }
        if result.count > bins { result.removeLast(result.count - bins) }
        
        if reader.status == .failed {
            throw WaveformError.readerFailed(reader.error?.localizedDescription ?? "Unknown error")
        }
        
        let maxV = max(result.max() ?? 0, 1e-6)
        let normalized = result.map { min(1, max(0, $0 / maxV)) }
        
        return normalized
    }
}
