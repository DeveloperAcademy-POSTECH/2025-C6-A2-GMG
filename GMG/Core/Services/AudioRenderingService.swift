//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import AVFAudio
import Accelerate
import Foundation

final class AudioRenderingService {

    func renderToAudioFile(score: Score) throws -> URL {
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
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("accompaniment-\(UUID().uuidString).m4a")

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
            throw NSError(domain: "BufferAlloc", code: -1)
        }

        let totalFrames = AVAudioFrameCount(score.totalDuration * outputFormat.sampleRate)

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
                continue  // 입력 데이터 부족 → 다음 루프 돌기

            case .error:
                throw NSError(domain: "OfflineRender", code: -1)

            @unknown default:
                break
            }
        }

        scorePlayer.stop()
        engine.stop()

        return outputURL
    }

    func mixAudioFiles(
        accompanimentURL: URL,
        vocalURL: URL
    ) throws -> URL {
        // 여기 나중에 Accelerate 믹싱 들어감
        throw NSError(domain: "", code: -1)
    }
}
