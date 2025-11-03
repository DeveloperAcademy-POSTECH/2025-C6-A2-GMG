//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

protocol RecordingModelStateProtocol {
    var isRecording: Bool { get }
    var recordingTime: TimeInterval { get }
    var recordingURL: URL? { get }
    var isPlaying: Bool { get }
    var amplitudes: [Float] { get }
    var countdown: Int { get }
}

protocol RecordingModelActionProtocol: AnyObject {
    func startRecording()
    func stopRecording()
    func updateRecordingURL(_ recordingURL: URL?)
    func startPlaying()
    func stopPlaying()
    func reset()
    func updateRecordingTime(_ recordingTime: TimeInterval)
    func appendAmplitdue(_ amplitude: Float)
    func updateCountdown(_ countdown: Int)
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

    init() {
        self.isRecording = false
        self.recordingTime = .zero
        self.recordingURL = nil
        self.isPlaying = false
        self.amplitudes = []
        self.countdown = .zero
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

    func appendAmplitdue(_ amplitude: Float) {
        self.amplitudes.append(amplitude)
    }
    
    func updateCountdown(_ countdown: Int) {
        self.countdown = countdown
    }
}
