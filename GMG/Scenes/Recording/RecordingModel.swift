//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

protocol RecordingModelStateProtocol {
    var isRecording: Bool { get }
    var recordingTime: TimeInterval { get }
    var recordingURL: URL? { get }
    var isPlaying: Bool { get }
    var amplitudes: [Float] { get }
    var countdown: Int { get }
    var scoreFactoryState: ScoreFactoryState? { get }
    var score: Score? { get }
}

protocol RecordingModelActionProtocol: AnyObject {
    func startRecording()
    func stopRecording()
    func updateRecordingURL(_ recordingURL: URL?)
    func startPlaying()
    func stopPlaying()
    func reset()
    func updateRecordingTime(_ recordingTime: TimeInterval)
    func appendAmplitude(_ amplitude: Float)
    func updateCountdown(_ countdown: Int)
    func updateScoreFactoryState(_ scoreFactoryState: ScoreFactoryState?)
    func finishScoreCreation(_ score: Score)
}

@Observable
final class RecordingModel:
    RecordingModelStateProtocol,
    RecordingModelActionProtocol
{
    private(set) var isRecording: Bool
    private(set) var recordingTime: TimeInterval
    private(set) var recordingURL: URL?
    private(set) var isPlaying: Bool
    private(set) var amplitudes: [Float]
    private(set) var countdown: Int
    private(set) var scoreFactoryState: ScoreFactoryState?
    private(set) var score: Score?

    init() {
        self.isRecording = false
        self.recordingTime = .zero
        self.recordingURL = nil
        self.isPlaying = false
        self.amplitudes = []
        self.countdown = .zero
        self.scoreFactoryState = nil
        self.score = nil
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

    func reset() {
        self.recordingTime = .zero
        self.recordingURL = nil
        self.amplitudes = []
    }

    func updateRecordingTime(_ recordingTime: TimeInterval) {
        self.recordingTime = recordingTime
    }

    func appendAmplitude(_ amplitude: Float) {
        self.amplitudes.append(amplitude)
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
