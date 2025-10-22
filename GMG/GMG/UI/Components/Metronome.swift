//
//  Metronome.swift
//  GMG
//
//  Created by 나현흠 on 10/21/25.
//

import SwiftUI
import AVFoundation

struct Metronome: View {
    let bpm: Int
    let isPlaying: Bool
    let selectedTimeSig: TimeSignature

    @State private var startDate: Date? = nil
    @State private var lastStepPlayed: Int = -1

    @State private var highPlayer: AVAudioPlayer? = nil
    @State private var lowPlayer: AVAudioPlayer? = nil

    // 박자에서 분자 뽑아내서 표시할 메트로놈 cd의 갯수 확정하기
    private var beatsPerBar: Int { selectedTimeSig.numerator }
    private var beatInterval: Double { 60.0 / Double(max(1, bpm)) }

    //지금 몇 번째 비트를 치고 있는지 계산해주는 역할
    private var currentBeatToShow: Int {
        guard isPlaying, let start = startDate else { return 0 }
        let elapsed = Date().timeIntervalSince(start)
        let step = Int(floor(elapsed / beatInterval))
        let beat = step % max(1, beatsPerBar)
        return beat
    }

    //오디오 출력 준비 (약간 audio play init 같은 느낌)
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[Metronome] AudioSession error: \(error)")
        }
    }

    //소리 플레이어 (소리 구분)
    private func loadPlayers() {
        
        if let url = Bundle.main.url(forResource: "Metronome_High", withExtension: "wav") {
            highPlayer = try? AVAudioPlayer(contentsOf: url)
            highPlayer?.volume = 1.0
            highPlayer?.prepareToPlay()
        } else {
            print("[Metronome] Missing resource: Metronome_High.wav (check target membership)")
        }
        
        if let url = Bundle.main.url(forResource: "Metronome_Low", withExtension: "wav") {
            lowPlayer = try? AVAudioPlayer(contentsOf: url)
            lowPlayer?.volume = 1.0
            lowPlayer?.prepareToPlay()
        } else {
            print("[Metronome] Missing resource: Metronome_Low.wav (check target membership)")
        }
    }

    // 소리 중 강박을 구분을 위한 인텍스 설정
    private func shouldUseHigh(beatIndex: Int) -> Bool {
        if selectedTimeSig.numerator == 6 && selectedTimeSig.denumerator == .eighth {
            return beatIndex == 0 || beatIndex == 3
        } else {
            return beatIndex == 0
        }
    }

    // 박자별 음성 재생
    private func playClick(for beatIndex: Int) {
        if shouldUseHigh(beatIndex: beatIndex) {
            guard let p = highPlayer else {
                print("[Metronome] highPlayer is nil")
                return
            }
            p.currentTime = 0
            p.play()
        } else {
            guard let p = lowPlayer else {
                print("[Metronome] lowPlayer is nil")
                return
            }
            p.currentTime = 0
            p.play()
        }
    }

    var body: some View {
        
        TimelineView(.periodic(from: .now, by: beatInterval)) { context in
            BeatBar(beatsPerBar: beatsPerBar, currentBeat: currentBeatToShow)
            .animation(.spring(response: 0.28, dampingFraction: 0.85, blendDuration: 0.2), value: beatsPerBar)
            .padding()
            .onChange(of: context.date) { _, _ in
                guard isPlaying, let start = startDate else { return }
                let step = Int(floor(Date().timeIntervalSince(start) / beatInterval))
                if step != lastStepPlayed {
                    lastStepPlayed = step
                    playClick(for: currentBeatToShow)
                }
            }
        }
        .onAppear {
            configureAudioSession()
            loadPlayers()
        }
        .onChange(of: selectedTimeSig) { _, _ in
            withAnimation(.spring(response: 0.28, dampingFraction: 0.85, blendDuration: 0.2)) {
                if isPlaying { startDate = Date(); lastStepPlayed = -1 }
            }
        }
        .onChange(of: isPlaying) { _, newValue in
            if newValue {
                startDate = Date()
                lastStepPlayed = -1
            }
        }
        .onChange(of: bpm) { _, _ in
            if isPlaying { startDate = Date(); lastStepPlayed = -1 }
        }
    }
}

extension Metronome {
    struct BeatBar: View {
        let beatsPerBar: Int
        let currentBeat: Int
        
        var body: some View {
            HStack(spacing: beatsPerBar == 6 ? 18 : 24) {
                ForEach(0 ..< beatsPerBar, id: \.self) { index in
                    Image(index == currentBeat ? "metronome_cd_fill" : "metronome_cd_empty")
                        .resizable()
                        .scaledToFit()
                        .frame(height: (beatsPerBar == 6 ? 33 : 44))
                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity),
                                                removal: .opacity))
                        .accessibilityLabel("Beat \(index + 1)" + (index == currentBeat ? " (current)" : ""))
                }
            }
        }
    }
}

#Preview {
    Metronome(bpm: 120, isPlaying: false, selectedTimeSig: .fourFour)
}
