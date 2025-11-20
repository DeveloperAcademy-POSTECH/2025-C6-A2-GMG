//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import AVFAudio
import Accelerate
import Foundation

enum ScoreAudioRenderingServiceError: Error {
    case bufferAllocationFailed
    case offlineRenderFailed
}

enum ScoreAudioRenderer {

    static func renderToAudioFile(score: Score, fileName: String? = nil) throws -> URL {
        let scorePlayer = ScorePlayer(score: score)
        try scorePlayer.prepareToExport()

        let engine = scorePlayer.engine

        // Offline rendering용 출력 포맷
        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)

        // Offline rendering 시작
        let maxFrames: AVAudioFrameCount = 4096
        try engine.enableManualRenderingMode(
            .offline,
            format: outputFormat,
            maximumFrameCount: maxFrames
        )

        try engine.start()

        // 출력 파일 URL 설정
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName ?? score.title)")

        let outputFile = try AVAudioFile(
            forWriting: outputURL,
            settings: outputFormat.settings
        )

        // Sequencer & PlayerNode 시작
        scorePlayer.sequencer.prepareToPlay()
        try scorePlayer.sequencer.start()
        scorePlayer.player.play()

        // 오디오 렌더링 버퍼
        guard
            let buffer = AVAudioPCMBuffer(
                pcmFormat: outputFormat,
                frameCapacity: maxFrames
            )
        else {
            throw ScoreAudioRenderingServiceError.bufferAllocationFailed
        }

        let totalDuration = score.totalDuration + 0.2
        let totalFrames = AVAudioFrameCount(totalDuration * outputFormat.sampleRate)

        /// 렌더링 루프
        while engine.manualRenderingSampleTime < AVAudioFramePosition(totalFrames) {
            let framesToRender = min(
                maxFrames,
                totalFrames - AVAudioFrameCount(engine.manualRenderingSampleTime)
            )

            let status = try engine.renderOffline(framesToRender, to: buffer)

            switch status {
            case .success:
                try outputFile.write(from: buffer)

            case .insufficientDataFromInputNode:
                buffer.frameLength = framesToRender
                memset(
                    buffer.int16ChannelData?[0], 0, Int(framesToRender) * MemoryLayout<Int16>.size)
                try outputFile.write(from: buffer)

            case .error:
                throw ScoreAudioRenderingServiceError.offlineRenderFailed

            case .cannotDoInCurrentContext:
                break

            @unknown default:
                break
            }
        }

        scorePlayer.stop()
        engine.stop()

        return outputURL
    }
}
