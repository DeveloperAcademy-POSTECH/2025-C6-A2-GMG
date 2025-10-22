//
//  MetronomeControlView.swift
//  C6demo
//
//  Created by 나현흠 on 10/21/25.
//

import SwiftUI


//MARK: - 해당 뷰는 메트로놈이 사용되는 예시를 보여드리기 위한 뷰입니다. 확인하셨다면 삭제하셔도 됩니다
struct MetronomeControlView: View {
    @State private var bpm: Int = 120
    @State private var isPlaying: Bool = false
    @State private var selectedTimeSig: TimeSignature = .fourFour

    var body: some View {
        VStack() {

            // 메트로놈 표시/틱 (값만 받아서 동작)
            Metronome(bpm: BPM(value: bpm), isPlaying: isPlaying, selectedTimeSig: selectedTimeSig)
            
            VStack(spacing: 42) {
                
                Button {
                    selectedTimeSig = .threeFour
                    isPlaying = true
                } label: {
                    Text("3/4")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTimeSig == .threeFour ? .blue.opacity(0.2) : .gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 142.5)
                
                
                Button {
                    selectedTimeSig = .fourFour
                    isPlaying = true
                } label: {
                    Text("4/4")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTimeSig == .fourFour ? .blue.opacity(0.2) : .gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 142.5)

                Button {
                    selectedTimeSig = .sixEight
                    isPlaying = true
                } label: {
                    Text("6/8")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTimeSig == .sixEight ? .blue.opacity(0.2) : .gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 142.5)
            }
            .padding(.bottom, 42)
            .padding(.top, selectedTimeSig == .sixEight ? 208 : 197)

            // 재생/정지 컨트롤
            HStack(spacing: 16) {
                Button {
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .accessibilityLabel(isPlaying ? "일시정지" : "재생")
                }
                .buttonStyle(.bordered)

                Button {
                    isPlaying = false
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .accessibilityLabel("정지")
                }
                .buttonStyle(.bordered)
            }

            // BPM 표시 (표시만)
            Text("BPM: \(bpm)")
                .font(.headline)
        }
        .padding()
        .onAppear() {
            isPlaying = true
        }
    }
}

#Preview {
    MetronomeControlView()
}
