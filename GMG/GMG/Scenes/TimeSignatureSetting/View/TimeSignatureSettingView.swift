//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct TimeSignatureSettingView: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(height: 42)
                .padding(.bottom, 81)
            Rectangle()
                .frame(height: 44)
                .padding(.bottom, 197)
            TimeSignatureSettingSection()
        }
    }
}

extension TimeSignatureSettingView {
    
    struct TimeSignatureButton: View {
        
        var body: some View {
            ZStack {
                Button {} label: {
                    RoundedRectangle(cornerRadius: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black.opacity(0.1))
                        )
                        .foregroundStyle(.green3)
                }
                .padding(.horizontal, 142)
                
                Text("4/4")
            }
        }
    }
    
    struct TimeSignatureSettingSection: View {
        var body: some View {
            VStack(spacing: 42) {
                TimeSignatureButton()
                TimeSignatureButton()
                TimeSignatureButton()
            }
            .padding(.bottom, 171)
        }
    }
}

#Preview {
    TimeSignatureSettingView()
}
