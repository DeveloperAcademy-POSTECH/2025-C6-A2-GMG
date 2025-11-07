//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI
import AVFoundation

struct WaveformUseView: View {
    @State private var amps: [Float] = []
    @State private var progress: Double = 0
    @State private var player: AVAudioPlayer?
    @State private var timer: Timer?

    private let bins = 150

    var body: some View {
        VStack(spacing: 16) {
            Waveform(amps: amps, progress: progress)
            
            ProgressSlider(progress: $progress)
            
            SampleLoadButton(amps: $amps, bins: bins)
            
            PlaySection(isEnabled: !amps.isEmpty) {
                playFromStart()
                
            }
        }
        .padding()
    }
}

private extension WaveformUseView {
    func playFromStart() {
        progress = 0
        timer?.invalidate()

        guard let url = Bundle.main.url(forResource: "sample", withExtension: "m4a") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("재생 실패:", error)
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { t in
            guard let p = player else {
                t.invalidate()
                return
            }
            if p.isPlaying {
                progress = p.duration > 0 ? p.currentTime / p.duration : 0
            } else {
                t.invalidate()
            }
        }
    }

    func highlightRange(progress: Double, totalBins: Int, windowBins: Int) -> Range<Int> {
        guard totalBins > 0 else { return 0..<0 }
        let idx = Int(round(progress * Double(max(0, totalBins - 1))))
        let half = windowBins / 2
        let lower = max(0, idx - half)
        let upper = min(totalBins, lower + windowBins)
        return lower..<upper
    }
}

extension WaveformUseView {

    struct Waveform: View {
        let amps: [Float]
        let progress: Double

        var body: some View {
                WaveformView(
                    amplitudes: amps,
                    highlight: amps.isEmpty ? nil : highlightRange(progress: progress, totalBins: amps.count, windowBins: 1),
                    progress: progress
                )
        }

        private func highlightRange(progress: Double, totalBins: Int, windowBins: Int) -> Range<Int> {
            guard totalBins > 0 else { return 0..<0 }
            let idx = Int(round(progress * Double(max(0, totalBins - 1))))
            let half = windowBins / 2
            let lower = max(0, idx - half)
            let upper = min(totalBins, lower + windowBins)
            return lower..<upper
        }
    }

    struct ProgressSlider: View {
        @Binding var progress: Double

        var body: some View {
            HStack {
                Text("0%")
                Slider(value: $progress, in: 0...1)
                Text("100%")
            }
        }
    }

    struct SampleLoadButton: View {
        @Binding var amps: [Float]
        let bins: Int

        var body: some View {
            HStack {
                Button("Load sample.m4a") {
                    Task {
                        do {
                            guard let url = Bundle.main.url(forResource: "sample", withExtension: "m4a") else { return }
                            amps = try await WaveformExtractor.extractAmplitudes(
                                from: url, bins: bins, mode: .rms, targetSampleRate: 44_100
                            )
                        } catch { print(error) }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    struct PlaySection: View {
        let isEnabled: Bool
        let action: () -> Void

        init(isEnabled: Bool, action: @escaping () -> Void) {
            self.isEnabled = isEnabled
            self.action = action
        }

        var body: some View {
            Button("Play", action: action)
                .disabled(!isEnabled)
        }
    }

    struct RoundedCornerRectangle: Shape {
        var radius: CGFloat = .infinity
        var corners: UIRectCorner = .allCorners

        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            )
            return Path(path.cgPath)
        }
    }
}

// MARK: - Preview
#Preview {
    WaveformUseView()
}
