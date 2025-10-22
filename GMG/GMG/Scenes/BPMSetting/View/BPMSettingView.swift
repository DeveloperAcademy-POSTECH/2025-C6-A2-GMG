//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct BPMSettingView: View {
    var model: BPMSettingStateProtocol
    var intent: BPMSettingIntentProtocol
    var bpmText: String {
        String(model.bpm.value)
    }
    
    var body: some View {
        ZStack {
            Color.backgroundLight1
                .ignoresSafeArea(edges: .all)
            
            VStack {
                Rectangle()
                    .frame(height:42)
                    .padding(.bottom, 81)
                
                Rectangle()
                    .frame(height:44)
                    .padding(.bottom, 116)
                
                BPMTapSession()
                
                BPMControlSession(
                    bpm: Binding(
                        get: { model.bpm.value },
                        set: { intent.setBPM($0) }
                    )
                )
                
                
            }
        }
    }
}

extension BPMSettingView {
    
    struct BPMTapButton: View {
        var body: some View {
            Button(action: {}, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.green4, lineWidth: 1)
                        )
                        .padding(.horizontal, 91)
                        .frame(maxHeight: 134)
                        .foregroundStyle(Color.green3)
                        
                    Text("Tap")
                        .font(Typography.DOSGothic.M15)
                        .foregroundStyle(.text1)
                }
            })
        }
    }
    
    struct BPMTapDescription: View {
        var body: some View {
            Text("원하는 박자를 \"Tap\" 해보세요")
                .font(Typography.NeoDunggeunmoPro.R4)
                .foregroundStyle(Color.text1)
        }
    }
    
    struct BPMTapSession: View {
        var body: some View {
            VStack(spacing: 0) {
                BPMTapButton()
                    .padding(.bottom, 10)
                BPMTapDescription()
            }
            .padding()
        }
    }
    
    struct BPMControlSession: View {
        @Binding var bpm: Int
        
        var body: some View {
            HStack(spacing: 0) {
                MinusButton()
                BPMIndicator(bpm: bpm)
                PlusButton()
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 74)
            .padding(.bottom, 137)
        }
    }
    
    struct BPMIndicator: View {
        var bpm: Int
        
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.gray2, lineWidth: 1)
                    )
                    .padding(.horizontal, 60)
                    .foregroundStyle(.gray1)
                    .frame(maxHeight: 50)
                Text("\(bpm)")
                    .font(Typography.NeoDunggeunmoPro.R4)
                    .foregroundStyle(.text1)
            }
        }
    }
    
    struct PlusButton: View {
        var body: some View {
            Button(action: {}, label: {
                Text("+")
                    .font(Typography.DOSGothic.M15)
                    .foregroundStyle(.text1)
            })
        }
    }
    
    struct MinusButton: View {
        var body: some View {
            Button(action: {}, label: {
                Text("-")
                    .font(Typography.DOSGothic.M15)
                    .foregroundStyle(.text1)
            })
        }
    }
}

#Preview {
    let model = BPMSettingModel()
    let intent = BPMSettingIntent(model: model)
    
    return BPMSettingView(model: model, intent: intent)
}
