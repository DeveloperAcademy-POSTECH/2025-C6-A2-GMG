//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import AVFAudio
import Accelerate
import Foundation

enum ScoreAudioRenderingServiceError: Error {
    case bufferAllocationFailed
    case offlineRenderFailed
}

protocol ScoreAudioRenderer {
    func renderToAudioFile(fileName: String?) throws -> URL
}

extension ScoreAudioRenderer {
    func renderToAudioFile() throws -> URL {
        try renderToAudioFile(fileName: nil)
    }
}

final class DefaultScoreAudioRenderer: ScoreAudioEngineBase, ScoreAudioRenderer {

    // MARK: - Rendering

    func renderToAudioFile(fileName: String?) throws -> URL {

        try prepareToExport()

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
        let outputURL = URL.temporaryDirectory.appending(
            component: "\(fileName ?? score.title).m4a")

        let outputFile = try AVAudioFile(
            forWriting: outputURL,
            settings: outputFormat.settings
        )

        // Sequencer & PlayerNode 시작
        sequencer.prepareToPlay()
        try sequencer.start()
        player.play()

        // 오디오 렌더링
        try performRendering(
            outputFile: outputFile,
            outputFormat: outputFormat,
            maxFrames: maxFrames
        )

        // 정리
        cleanup()

        return outputURL
    }

    private func performRendering(
        outputFile: AVAudioFile,
        outputFormat: AVAudioFormat,
        maxFrames: AVAudioFrameCount
    ) throws {
        guard
            let buffer = AVAudioPCMBuffer(
                pcmFormat: outputFormat,
                frameCapacity: maxFrames
            )
        else {
            throw ScoreAudioRenderingServiceError.bufferAllocationFailed
        }

        let totalDuration = score.totalDuration + 0.2  //첫 노트 잘림 방지 및 파일이 뚝 끊길 수도 있는 문제 방지용 TailTime 0.2 추가
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
                    buffer.int16ChannelData?[0],
                    0,
                    Int(framesToRender) * MemoryLayout<Int16>.size
                )
                try outputFile.write(from: buffer)

            case .error:
                throw ScoreAudioRenderingServiceError.offlineRenderFailed

            case .cannotDoInCurrentContext:
                break

            @unknown default:
                break
            }
        }
    }

    private func cleanup() {
        player.stop()
        sequencer.stop()
        engine.stop()
    }
}
