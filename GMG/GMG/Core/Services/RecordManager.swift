//
//  RecordManager.swift
//  SwiftF0
//
//  Created by 정희균 on 10/28/25.
//

import AVFAudio
import AudioKit
import AudioKitEX
import Combine
import Foundation
internal import UniformTypeIdentifiers

enum RecordManagerError: Error {
    case audioEngineInputNodeNotAvailable
}

final class RecordManager {
    private var audioRecorder: NodeRecorder?
    private var highpassFilter: HighPassFilter?
    private var amplitudeTap: AmplitudeTap?
    private var fader: Fader?

    private(set) var isRecordingPublisher: CurrentValueSubject<Bool, Never>
    private(set) var recordedDurationPublisher: CurrentValueSubject<TimeInterval, Never>
    private(set) var amplitudePublisher: CurrentValueSubject<Float, Never>
    
    private var cancellables: Set<AnyCancellable>

    init() {
        self.audioRecorder = nil
        self.amplitudeTap = nil
        self.fader = nil

        self.isRecordingPublisher = CurrentValueSubject<Bool, Never>(false)
        self.recordedDurationPublisher = CurrentValueSubject<TimeInterval, Never>(.zero)
        self.amplitudePublisher = CurrentValueSubject<Float, Never>(0.0)
        
        self.cancellables = Set<AnyCancellable>()
    }

    func startRecord() throws {
        try AudioConductor.shared.setAudioMode(.record)

        guard let inputNode = AudioConductor.shared.inputNode else {
            throw RecordManagerError.audioEngineInputNodeNotAvailable
        }
        
        let highpassFilter = HighPassFilter(inputNode)
        let amplitudeTap = AmplitudeTap(highpassFilter, analysisMode: .peak) { [weak self] amplitude in
            guard let self else { return }
            self.amplitudePublisher.send(amplitude)
        }
        let fader = Fader(highpassFilter)
        let audioRecorder = try NodeRecorder(node: inputNode)

        AudioConductor.shared.addOutput(fader)

        try AudioConductor.shared.start()
        
        amplitudeTap.start()
        try audioRecorder.record()
        
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let recordedDuration = self.audioRecorder?.recordedDuration else { return }
                self.recordedDurationPublisher.send(recordedDuration)
            }
            .store(in: &cancellables)
        
        self.audioRecorder = audioRecorder
        self.highpassFilter = highpassFilter
        self.amplitudeTap = amplitudeTap
        self.fader = fader

        self.isRecordingPublisher.send(true)
    }

    func stopRecord() -> URL? {
        audioRecorder?.stop()
        amplitudeTap?.stop()

        try? AudioConductor.shared.setAudioMode(nil)

        self.isRecordingPublisher.send(false)
        self.cancellables.removeAll()

        guard let tempUrl = audioRecorder?.audioFile?.url else {
            return nil
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            "recording-\(Date().ISO8601Format()).caf",
            conformingTo: .audio
        )

        try? FileManager.default.moveItem(at: tempUrl, to: url)
        
        self.audioRecorder = nil
        self.highpassFilter = nil
        self.amplitudeTap = nil
        self.fader = nil
        
        return url
    }
}
