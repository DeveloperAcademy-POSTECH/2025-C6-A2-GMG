//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Combine
import Foundation

protocol RecordingIntentProtocol {
    func onTapRecordButton()
    func onTapStopRecordButton()
    func onTapResetButton()
    func onTapPlayButton(_ url: URL)
    func onTapStopPlayButton()
}

final class RecordingIntent: RecordingIntentProtocol {
    private weak var model: RecordingModelActionProtocol?
    private let recordManager: RecordManager
    private let playbackManager: PlaybackManager

    private var cancellables: Set<AnyCancellable>

    init(model: RecordingModelActionProtocol) {
        self.model = model
        self.recordManager = RecordManager()
        self.playbackManager = PlaybackManager()

        self.cancellables = Set<AnyCancellable>()

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

        recordManager.amplitudePublisher
            .sink { [weak self] amplitude in
                self?.model?.appendAmplitdue(amplitude)
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
                try recordManager.startRecord()
            } catch {
                print(error)
            }
        }
    }

    func onTapStopRecordButton() {
        let url: URL? = recordManager.stopRecord()

        model?.updateRecordingURL(url)
    }

    func onTapResetButton() {
        onTapStopPlayButton()

        model?.reset()
    }

    func onTapPlayButton(_ url: URL) {
        do {
            try playbackManager.play(url)
        } catch {
            print(error)
        }
    }

    func onTapStopPlayButton() {
        playbackManager.stop()
    }
}
