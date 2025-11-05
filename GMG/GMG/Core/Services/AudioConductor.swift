//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import AVFAudio
import AudioKit

enum AudioMode {
    case playback
    case record

    var category: AVAudioSession.Category {
        switch self {
        case .playback:
            return .playback
        case .record:
            return .playAndRecord
        }
    }

    var options: AVAudioSession.CategoryOptions {
        switch self {
        case .playback:
            return []
        case .record:
            return [.defaultToSpeaker]
        }
    }
}

final class AudioConductor {
    static let shared: AudioConductor = AudioConductor()

    private(set) var audioMode: AudioMode?

    private var engine: AudioEngine?
    private var mixer: Mixer?

    var inputNode: AudioEngine.InputNode? {
        engine?.input
    }

    private init() {}

    private func setup() throws {
        let engine = AudioEngine()
        let mixer = Mixer()

        engine.output = mixer

        self.engine = engine
        self.mixer = mixer
    }

    private func teardown() throws {
        self.mixer?.stop()
        self.engine?.stop()
        
        self.engine?.output = nil

        self.mixer = nil
        self.engine = nil
    }

    func setAudioMode(_ mode: AudioMode?) throws {
        try teardown()
        try deactivateAudioSession()

        if let mode {
            try setCategoryAudioSession(mode)
            try activateAudioSession()
            try setup()
        }

        self.audioMode = mode
    }

    func start() throws {
        try self.engine?.start()
    }

    func stop() {
        self.engine?.stop()
    }

    func addOutput(_ node: Node) {
        self.mixer?.addInput(node)
    }

    func removeOutput(_ node: Node) {
        self.mixer?.removeInput(node)
    }

    func setCategoryAudioSession(_ mode: AudioMode) throws {
        let audioSession = AVAudioSession.sharedInstance()
        let category = mode.category
        let options = mode.options

        switch mode {
        case .playback:
            try audioSession.setCategory(category)
        case .record:
            try audioSession.setCategory(
                category,
                mode: .measurement,
                options: options
            )
            try audioSession.setPreferredSampleRate(48_000)
        }
    }

    func activateAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setActive(true)
    }

    func deactivateAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setActive(false)
    }
}
