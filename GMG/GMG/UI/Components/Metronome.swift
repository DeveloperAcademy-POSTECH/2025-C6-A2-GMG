//
//  Metronome.swift
//  GMG
//
//  Created by 나현흠 on 10/21/25.
//

import SwiftUI
import AVFoundation

struct Metronome: View {
    let bpm: BPM //bpm
    let isPlaying: Bool //메트로놈 플레이 여부
    let selectedTimeSig: TimeSignature //박자

    @State private var startDate: Date? = nil //isPlaying이 true가 되는 순간의 현재 시간을 저장해서 그 이후 경과 시간을 계산하는 기준점으로 사용
    @State private var lastStepPlayed: Int = -1 //직전에 재생한 박자의 인덱스를 저장하는 상태

    @State private var highPlayer: AVAudioPlayer? = nil //메트로놈 강박 Player
    @State private var lowPlayer: AVAudioPlayer? = nil //메트로놈 약박 Player

    // 박자에서 분자 뽑아내서 표시할 메트로놈 cd의 갯수 확정하기
    private var beatsPerBar: Int { selectedTimeSig.numerator }
    private var beatInterval: Double { 60.0 / Double(max(1, bpm.value)) }

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

    // 소리 중 강박을 구분을 위한 인텍스 설정 (3/4, 4/4 박자는 첫 번째 박만 강박이지만, 6/8 박자의 경우 1, 4번 박에 강박을 줘야 함) *강박: Metronome 재생 중 기준을 잡는 높은 음
    private func shouldUseHigh(beatIndex: Int) -> Bool {
        if selectedTimeSig.numerator == 6 && selectedTimeSig.denumerator == .eighth {
            return beatIndex == 0 || beatIndex == 3
        } else {
            return beatIndex == 0
        }
    }

    // 박자별 High or Low 음성 재생
    private func playBeatSound(for beatIndex: Int) {
        if shouldUseHigh(beatIndex: beatIndex) {
            guard let audioPlayer = highPlayer else {
                print("[Metronome] highPlayer is nil")
                return
            }
            audioPlayer.currentTime = 0
            audioPlayer.play()
        } else {
            guard let audioPlayer = lowPlayer else {
                print("[Metronome] lowPlayer is nil")
                return
            }
            audioPlayer.currentTime = 0
            audioPlayer.play()
        }
    }

    var body: some View {
        
        //TimelineView를 사용해 beatInterval마다 뷰가 업데이트 되도록 구성함
        TimelineView(.periodic(from: .now, by: beatInterval)) { context in
            BeatBar(beatsPerBar: beatsPerBar, currentBeat: currentBeatToShow)
                .animation(.spring(response: 0.28, dampingFraction: 0.85, blendDuration: 0.2), value: beatsPerBar)
                .padding()
                .onChange(of: context.date) { _, _ in
                    guard isPlaying, let start = startDate else { return }
                    let step = Int(floor(Date().timeIntervalSince(start) / beatInterval))
                    if step != lastStepPlayed {
                        lastStepPlayed = step
                        playBeatSound(for: currentBeatToShow)
                    }
                }
        }
        .onAppear {
            configureAudioSession()
            loadPlayers()
        }
        .onDisappear() {
            // audio session 관련 메모리 해제 로직
            // 1. 플레이어 중지 및 메모리에서 해제
            highPlayer?.stop()
            lowPlayer?.stop()
            highPlayer = nil
            lowPlayer = nil
            
            // 2. 오디오 세션 비활성화
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print("[Metronome] AudioSession deactivation error: \(error)")
            }
        }
        //박자가 변경될 때 자연스럽게 CD 갯수가 바뀌는 애니메이션
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
        .onChange(of: bpm.value) { _, _ in
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
                    
                    if index == currentBeat {
                        SelectedCD(beatsPerBar: beatsPerBar)
                    } else {
                        glow_cd(beatsPerBar: beatsPerBar)
                    }
                    
//                    Image(index == currentBeat ? "metronome_cd_fill" : "glow_cd")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(height: (beatsPerBar == 6 ? 33 : 44))
//                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity),
//                                                removal: .opacity))
                }
            }
        }
    }
    
    struct SelectedCD: View {
        var beatsPerBar: Int
        
        var body: some View {
            Circle()
                .frame(width: beatsPerBar == 6 ? 34 : 46)
                .foregroundStyle(.green4)
                .shadow(color: .green4, radius: 10)
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
        }
    }
    
    struct glow_cd: View {
        var beatsPerBar: Int
        
        var body: some View {
            Image("glow_cd")
                .resizable()
                .scaledToFit()
                .frame(width: beatsPerBar == 6 ? 34 : 46)
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                
        }
    }
}

#Preview {
    Metronome(bpm: BPM(value: 120), isPlaying: false, selectedTimeSig: .fourFour)
}
