//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

protocol RecordingModelStateProtocol {
    var isRecordPermissionAlertPresented: Bool { get }
    var isRecording: Bool { get }
    var recordingTime: TimeInterval { get }
    var recordingURL: URL? { get }
    var isPlaying: Bool { get }
    var audioLevels: [Float] { get }
    var countdown: Int { get }
    var isResetConfirmationAlertPresented: Bool { get }
    var scoreFactoryState: ScoreFactoryState? { get }
    var score: Score? { get }
}

protocol RecordingModelActionProtocol: AnyObject {
    func setRecordPermissionAlertPresented(_ isPresented: Bool)
    func startRecording()
    func stopRecording()
    func updateRecordingURL(_ recordingURL: URL?)
    func startPlaying()
    func stopPlaying()
    func setResetConfirmationAlertPresented(_ isPresented: Bool)
    func reset()
    func updateRecordingTime(_ recordingTime: TimeInterval)
    func appendAudioLevel(_ audioLevel: Float)
    func resetAudioLevels()
    func updateCountdown(_ countdown: Int)
    func updateScoreFactoryState(_ scoreFactoryState: ScoreFactoryState?)
    func finishScoreCreation(_ score: Score)
}

@Observable
final class RecordingModel:
    RecordingModelStateProtocol,
    RecordingModelActionProtocol
{
    private(set) var isRecordPermissionAlertPresented: Bool
    private(set) var isRecording: Bool
    private(set) var recordingTime: TimeInterval
    private(set) var recordingURL: URL?
    private(set) var isPlaying: Bool
    private(set) var audioLevels: [Float]
    private(set) var countdown: Int
    private(set) var isResetConfirmationAlertPresented: Bool
    private(set) var scoreFactoryState: ScoreFactoryState?
    private(set) var score: Score?

    init() {
        self.isRecordPermissionAlertPresented = false
        self.isRecording = false
        self.recordingTime = .zero
        self.recordingURL = nil
        self.isPlaying = false
        self.audioLevels = []
        self.countdown = .zero
        self.isResetConfirmationAlertPresented = false
        self.scoreFactoryState = nil
        self.score = nil
    }

    func setRecordPermissionAlertPresented(_ isPresented: Bool) {
        self.isRecordPermissionAlertPresented = isPresented
    }

    func startRecording() {
        self.isRecording = true
    }

    func stopRecording() {
        self.isRecording = false
    }

    func updateRecordingURL(_ recordingURL: URL?) {
        self.recordingURL = recordingURL
    }

    func startPlaying() {
        self.isPlaying = true
    }

    func stopPlaying() {
        self.isPlaying = false
    }

    func setResetConfirmationAlertPresented(_ isPresented: Bool) {
        self.isResetConfirmationAlertPresented = isPresented
    }

    func reset() {
        self.recordingTime = .zero
        self.recordingURL = nil
        resetAudioLevels()
    }

    func updateRecordingTime(_ recordingTime: TimeInterval) {
        self.recordingTime = recordingTime
    }

    func appendAudioLevel(_ audioLevel: Float) {
        self.audioLevels.append(audioLevel)
    }

    func resetAudioLevels() {
        self.audioLevels = []
    }

    func updateCountdown(_ countdown: Int) {
        self.countdown = countdown
    }

    func updateScoreFactoryState(_ scoreFactoryState: ScoreFactoryState?) {
        self.scoreFactoryState = scoreFactoryState
    }

    func finishScoreCreation(_ score: Score) {
        self.score = score
    }
}
