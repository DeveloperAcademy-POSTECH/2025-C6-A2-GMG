//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Combine
import Foundation
import Observation

@Observable
final class RecordingContainer {
    private(set) var state: RecordingState

    init() {
        self.state = .mock
    }

    func send(_ intent: RecordingIntent) {
        switch intent {
        case .startRecord:
            startRecord()
        case .stopRecord:
            stopRecord()
        case .retakeRecord:
            retakeRecord()
        }
    }

    // MARK: - Implement Intents

    private var audioRecorder: AudioRecorder?
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()

    private func startRecord() {
        do {
            if self.audioRecorder == nil {
                try setupAudioRecorder()
            }

            try audioRecorder?.startRecord()
        } catch {
            print(String(describing: error))
        }
    }

    private func stopRecord() {
        do {
            try self.audioRecorder?.stopRecord()
        } catch {
            print(String(describing: error))
        }
    }

    private func retakeRecord() {
        do {
            try self.audioRecorder?.retakeRecord()
        } catch {
            print(String(describing: error))
        }
    }

    private func setupAudioRecorder() throws {
        let audioRecorder = try AudioRecorder()

        audioRecorder.isRecordingPublisher
            .sink { [weak self] isRecording in
                guard let self else { return }

                self.state = self.state.copy(isRecording: isRecording)
            }
            .store(in: &cancellables)

        audioRecorder.fftMangitudesPublisher
            .sink { [weak self] fftMagnitudes in
                guard let self else { return }

                self.state = self.state.copy(frequencies: fftMagnitudes)
            }
            .store(in: &cancellables)

        audioRecorder.recordedDurationPublisher
            .sink { [weak self] recordedDuration in
                guard let self else { return }

                self.state = self.state.copy(elapsedTime: recordedDuration)
            }
            .store(in: &cancellables)

        self.audioRecorder = audioRecorder
    }
}
