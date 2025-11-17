//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import AVFAudio
import Combine
import Foundation
import UIKit

protocol RecordingIntentProtocol {
    func onAppear() async
    func onTapOpenSettingsButton()
    func onTapRecordPermissionAlertCancelButton()
    func onTapRecordButton()
    func onTapSkipButton()
    func onTapStopRecordButton()
    func onTapShowResetConfirmationAlertButton()
    func onTapResetConfirmationAlertCancelButton()
    func onTapResetButton()
    func onTapPlayButton(_ url: URL)
    func onTapStopPlayButton()
    func onTapNextButton(_ url: URL, completion: @escaping () -> Void)
}

final class RecordingIntent: RecordingIntentProtocol {
    private weak var model: RecordingModelActionProtocol?

    private let scoreRepository: ScoreRepository

    private let recordManager: RecordManager
    private let playbackManager: PlaybackManager

    private let scoreFactory: ScoreFactory

    private var cancellables: Set<AnyCancellable>

    private var countdownTask: Task<Void, Never>?
    private var scoreCreationTask: Task<Void, Never>?

    init(
        model: RecordingModelActionProtocol,
        scoreRepository: ScoreRepository
    ) {
        self.model = model

        self.scoreRepository = scoreRepository

        self.recordManager = RecordManager()
        self.playbackManager = PlaybackManager()

        self.scoreFactory = ScoreFactory()

        self.cancellables = Set<AnyCancellable>()

        self.countdownTask = nil
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

    func onAppear() async {
        if AVAudioApplication.shared.recordPermission == .undetermined {
            await AVAudioApplication.requestRecordPermission()
        }
    }

    func onTapOpenSettingsButton() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }

        guard UIApplication.shared.canOpenURL(url) else { return }

        UIApplication.shared.open(url)

        onTapRecordPermissionAlertCancelButton()
    }

    func onTapRecordPermissionAlertCancelButton() {
        guard let model else { return }

        model.setRecordPermissionAlertPresented(false)
    }

    func onTapRecordButton() {
        guard let model else { return }

        guard AVAudioApplication.shared.recordPermission == .granted else {
            model.setRecordPermissionAlertPresented(true)
            return
        }

        self.countdownTask?.cancel()

        self.countdownTask = Task {
            do {
                try recordManager.prepareToRecord()
            } catch {
                Logger.error(String(describing: error))
            }

            await withTaskCancellationHandler {
                for i in (0...3).reversed() {
                    model.updateCountdown(i)
                    if i > 0 {
                        try? await Task.sleep(for: .seconds(1))
                    }
                }
            } onCancel: {
                Task { @MainActor in
                    model.updateCountdown(0)
                }
            }

            recordManager.record()
        }
    }

    func onTapSkipButton() {
        self.countdownTask?.cancel()

        self.countdownTask = nil
    }

    func onTapStopRecordButton() {
        guard let model else { return }

        let url: URL? = recordManager.stop()

        model.updateRecordingURL(url)
    }

    func onTapShowResetConfirmationAlertButton() {
        guard let model else { return }

        model.setResetConfirmationAlertPresented(true)
    }

    func onTapResetConfirmationAlertCancelButton() {
        guard let model else { return }

        model.setResetConfirmationAlertPresented(false)
    }

    func onTapResetButton() {
        onTapStopPlayButton()

        guard let model else { return }

        model.reset()

        onTapResetConfirmationAlertCancelButton()
    }

    func onTapPlayButton(_ url: URL) {
        guard let model else { return }

        do {
            model.resetAudioLevels()

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
            guard let self, let model = self.model
            else { return }

            do {
                let score: Score = try await self.scoreFactory.createScore(audioURL: url)

                try self.scoreRepository.insert(score)

                try? await Task.sleep(for: .seconds(0.5))

                model.updateScoreFactoryState(nil)
                model.finishScoreCreation(score)
                completion()
            } catch {
                model.updateScoreFactoryState(nil)
                Logger.error(String(describing: error))
            }
        }
    }
}
