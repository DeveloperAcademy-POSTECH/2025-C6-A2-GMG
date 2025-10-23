//
//  Metronome.swift
//  GMG
//
//  Created by 나현흠 on 10/21/25.
//

import SwiftUI
import AVFoundation
import Combine

struct Metronome: View {
    let bpm: BPM
    let isPlaying: Bool
    let timeSignature: TimeSignature
    
    @State private var currentBeat: Int = 0
    @State private var timer: Publishers.Autoconnect<Timer.TimerPublisher>
    
    @State private var highPlayer: AVAudioPlayer? = nil //메트로놈 강박 Player
    @State private var lowPlayer: AVAudioPlayer? = nil //메트로놈 약박 Player
    
    // 박자에서 분자 뽑아내서 표시할 메트로놈 cd의 갯수 확정하기
    private var beatsPerMeasure: Int { timeSignature.numerator }
    
    init(
        bpm: BPM,
        isPlaying: Bool,
        timeSignature: TimeSignature
    ) {
        self.bpm = bpm
        self.isPlaying = isPlaying
        self.timeSignature = timeSignature
        
        self.timer = Timer.publish(
            every: bpm.beatDuration(),
            on: .main,
            in: .common
        )
        .autoconnect()
    }
    
    var body: some View {
        //TimelineView를 사용해 beatInterval마다 뷰가 업데이트 되도록 구성함
        BeatMeasure(beatsPerMeasure: beatsPerMeasure, currentBeat: currentBeat, isPlaying: isPlaying)
            .padding()
            .onAppear {
                configureAudioSession()
                
                loadHighPlayer()
                loadLowPlayer()
            }
            .onDisappear {
                unloadHighPlayer()
                unloadLowPlayer()
                
                deactiveAudioSession()
            }
            .onReceive(timer) { _ in
                if isPlaying {
                    currentBeat = (currentBeat + 1) % beatsPerMeasure
                    
                    playBeatSound(for: currentBeat)
                }
            }
            .onChange(of: bpm.value) { _, _ in
                timer.upstream.connect().cancel()
                timer = Timer.publish(
                    every: bpm.beatDuration(),
                    on: .main,
                    in: .common
                ).autoconnect()
            }
            .onChange(of: isPlaying) { _, newValue in
                if newValue == false {
                    currentBeat = 0
                }
            }
    }
}

//MARK: - SubView
extension Metronome {
    
    struct BeatMeasure: View {
        let beatsPerMeasure: Int
        let currentBeat: Int
        let isPlaying: Bool
        
        private var spacing: CGFloat { beatsPerMeasure == 6 ? 18 : 24 }
        
        var body: some View {
            HStack(spacing: spacing) {
                ForEach(0 ..< beatsPerMeasure, id: \.self) { index in
                    if isPlaying && index == currentBeat {
                        SelectedCD(beatsPerMeasure: beatsPerMeasure)
                    } else {
                        UnselectedCD(beatsPerMeasure: beatsPerMeasure)
                    }
                }
            }
            .animation(
                .spring(
                    response: 0.28,
                    dampingFraction: 0.85,
                    blendDuration: 0.2
                ),
                value: beatsPerMeasure
            )
        }
    }
    
    struct SelectedCD: View {
        var beatsPerMeasure: Int
        private var width: CGFloat { beatsPerMeasure == 6 ? 34 : 46 }
        
        var body: some View {
            Circle()
                .frame(width: width)
                .foregroundStyle(.green4)
                .shadow(color: .green4, radius: 10)
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
        }
    }
    
    struct UnselectedCD: View {
        var beatsPerMeasure: Int
        private var width: CGFloat { beatsPerMeasure == 6 ? 34 : 46 }
        
        var body: some View {
            Image(.metronomeCD)
                .resizable()
                .scaledToFit()
                .frame(width: width)
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
        }
    }
}

//MARK: - Methods
extension Metronome {
    
    //오디오 출력 준비 (약간 audio play init 같은 느낌)
    //TODO: - 오디오 세션 녹음 중에는 .playAndRecord 여야 함 -> 추후 논의 필요
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[Metronome] AudioSession error: \(error)")
        }
    }
    
    private func deactiveAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        } catch {
            print(
                "[Metronome] AudioSession deactivation error: \(error)"
            )
        }
    }
    
    private func loadHighPlayer() {
        guard highPlayer == nil else { return }
        
        guard
            let url = Bundle.main.url(
                forResource: "MetronomeHigh",
                withExtension: "wav"
            )
        else {
            print(
                "[Metronome] Missing resource: Metronome_High.wav (check target membership)"
            )
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            
            player.volume = 1.0
            player.prepareToPlay()
            
            self.highPlayer = player
        } catch {
            print("[Metronome] Failed to initialize audio player for high")
        }
    }
    
    private func loadLowPlayer() {
        guard lowPlayer == nil else { return }
        
        guard
            let url = Bundle.main.url(
                forResource: "MetronomeLow",
                withExtension: "wav"
            )
        else {
            print(
                "[Metronome] Missing resource: Metronome_Low.wav (check target membership)"
            )
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            
            player.volume = 1.0
            player.prepareToPlay()
            
            self.lowPlayer = player
        } catch {
            print("[Metronome] Failed to initialize audio player for low")
        }
    }
    
    private func unloadHighPlayer() {
        guard let highPlayer else { return }
        highPlayer.stop()
        
        self.highPlayer = nil
    }
    
    private func unloadLowPlayer() {
        guard let lowPlayer else { return }
        lowPlayer.stop()
        
        self.lowPlayer = nil
    }
    
    // 소리 중 강박을 구분을 위한 인텍스 설정 (3/4, 4/4 박자는 첫 번째 박만 강박이지만, 6/8 박자의 경우 1, 4번 박에 강박을 줘야 함) *강박: Metronome 재생 중 기준을 잡는 높은 음
    private func shouldUseHigh(beatIndex: Int) -> Bool {
        if timeSignature.numerator == 6 && timeSignature.denumerator == .eighth {
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
}

#Preview {
    struct PreviewWrapper: View {
        @State private var bpm: Int = 100
        @State private var isPlaying: Bool = false
        @State private var timeSignature: TimeSignature = .fourFour

        var body: some View {
            VStack(spacing: 20) {
                Metronome(
                    bpm: BPM(value: bpm),
                    isPlaying: isPlaying,
                    timeSignature: timeSignature
                )

                Button(isPlaying ? "Stop" : "Play") {
                    isPlaying.toggle()
                }
                .buttonStyle(.bordered)

                Stepper("BPM: \(bpm)", value: $bpm, in: 30...320)
                
                HStack(spacing: 30) {
                    Button("3/4") {
                        timeSignature = .threeFour
                    }
                    .buttonStyle(.bordered)
                    Button("4/4") {
                        timeSignature = .fourFour
                    }
                    .buttonStyle(.bordered)
                    Button("6/8") {
                        timeSignature = .sixEight
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

// MARK: - BPM Extension

extension BPM {
    func beatDuration() -> TimeInterval {
        return 60.0 / TimeInterval(max(1, self.value))
    }
}
