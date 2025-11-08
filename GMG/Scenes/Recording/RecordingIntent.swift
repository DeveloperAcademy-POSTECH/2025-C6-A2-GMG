//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Combine
import Foundation

protocol RecordingIntentProtocol {
    func onTapRecordButton()
    func onTapStopRecordButton()
    func onTapResetButton()
    func onTapPlayButton(_ url: URL)
    func onTapStopPlayButton()
    func onTapNextButton(_ url: URL, completion: @escaping () -> Void)
}

final class RecordingIntent: RecordingIntentProtocol {
    private weak var model: RecordingModelActionProtocol?

    private let recordManager: RecordManager
    private let playbackManager: PlaybackManager

    private let scoreFactory: ScoreFactory

    private var cancellables: Set<AnyCancellable>

    private var scoreCreationTask: Task<Void, Never>?

    init(model: RecordingModelActionProtocol) {
        self.model = model

        self.recordManager = RecordManager()
        self.playbackManager = PlaybackManager()

        self.scoreFactory = ScoreFactory()

        self.cancellables = Set<AnyCancellable>()

        self.scoreCreationTask = nil

        setupPublishers()
    }

    private func setupPublishers() {
        recordManager.isRecordingPublisher
            .sink { [weak self] isRecording in
                if isRecording == true {
                    self?.model?.startRecording()
                } else {
                    self?.model?.stopRecording()
                }
            }
            .store(in: &cancellables)

        recordManager.recordedDurationPublisher
            .sink { [weak self] recordedDuration in
                self?.model?.updateRecordingTime(recordedDuration)
            }
            .store(in: &cancellables)

        recordManager.audioLevelPublisher
            .sink { [weak self] audioLevel in
                self?.model?.appendAudioLevel(audioLevel)
            }
            .store(in: &cancellables)

        playbackManager.isPlayingPublisher
            .sink { [weak self] isPlaying in
                if isPlaying == true {
                    self?.model?.startPlaying()
                } else {
                    self?.model?.stopPlaying()
                }
            }
            .store(in: &cancellables)

        playbackManager.playedDurationPublisher
            .sink { [weak self] playedDuration in
                self?.model?.updateRecordingTime(playedDuration)
            }
            .store(in: &cancellables)

        playbackManager.audioLevelPublisher
            .sink { [weak self] audioLevel in
                self?.model?.appendAudioLevel(audioLevel)
            }
            .store(in: &cancellables)

        scoreFactory.scoreFactoryStatePublisher
            .sink { [weak self] scoreFactoryState in
                self?.model?.updateScoreFactoryState(scoreFactoryState)
            }
            .store(in: &cancellables)
    }

    func onTapRecordButton() {
        Task {
            model?.updateCountdown(3)

            try? await Task.sleep(for: .seconds(1))

            model?.updateCountdown(2)

            try? await Task.sleep(for: .seconds(1))

            model?.updateCountdown(1)

            try? await Task.sleep(for: .seconds(1))

            model?.updateCountdown(0)

            do {
                try recordManager.record()
            } catch {
                Logger.error(String(describing: error))
            }
        }
    }

    func onTapStopRecordButton() {
        let url: URL? = recordManager.stop()

        model?.updateRecordingURL(url)
    }

    func onTapResetButton() {
        onTapStopPlayButton()

        model?.reset()
    }

    func onTapPlayButton(_ url: URL) {
        do {
            model?.resetAudioLevels()

            try playbackManager.play(url)
        } catch {
            Logger.error(String(describing: error))
        }
    }

    func onTapStopPlayButton() {
        playbackManager.stop()
    }

    func onTapNextButton(_ url: URL, completion: @escaping () -> Void) {
        onTapStopPlayButton()

        scoreCreationTask?.cancel()

        scoreCreationTask = Task { [weak self] in
            guard let self else { return }

            do {
                // TODO: Swift Concurrency 방법 찾아보기!
                // DispatchQueue.global()을 사용하지 않으면 MainThread에서 실행되어 로딩 화면이 안나옴
                let score: Score = try await withCheckedThrowingContinuation {
                    continuation in
                    DispatchQueue.global().async {
                        do {
                            let score: Score = try self.scoreFactory
                                .createScore(audioUrl: url)
                            continuation.resume(returning: score)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }

                self.model?.updateScoreFactoryState(nil)
                self.model?.finishScoreCreation(score)
                completion()
            } catch {
                self.model?.updateScoreFactoryState(nil)
                Logger.error(String(describing: error))
            }
        }
    }
}
