//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct BPMSettingView<Container: BPMSettingContainerProtocol & ObservableObject>: View {
    
    @StateObject private var container: Container

    init(container: @autoclosure @escaping () -> Container) {
        _container = StateObject(wrappedValue: container())
    }
    
    var body: some View {
        //MARK: CustomNavigationBar 삽입 시 제거 예정
        Rectangle()
            .frame(height: 42)
            .padding(.bottom, 81)
        
        Metronome()
        
        VStack(spacing: 10) {
            BPMTapButton()
            
            BPMTapDescription()
        }
        
    }
}

extension BPMSettingView {
    struct BPMTapButton: View {
        var body: some View {
            RoundedRectangle(cornerRadius: 24)
                .padding(.horizontal, 81)
                .padding(.bottom, 10)
                
        }
    }
    
    struct BPMTapDescription: View {
        var body: some View {
            Text("원하는 박자를 \"Tap\" 해보세요")
                .font(Typography.NeoDonggeunmoPro.R4)
        }
    }
}

#Preview {
    BPMSettingView(container: BPMSettingContainer())
}
