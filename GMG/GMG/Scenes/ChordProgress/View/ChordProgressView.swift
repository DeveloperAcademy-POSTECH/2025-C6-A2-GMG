import SwiftUI

struct ChordProgressView: View {
    var body: some View {
        ZStack {
            Color.backgroundLight1.ignoresSafeArea()
            
            VStack(spacing: 0) {
                NavigationHeader(onClickHome: {}, onClickSave: {})
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                
                // ToolbarView
                ToolbarView(onClickTrash: {}, onClickUndo: {}, onClickRedo: {})
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                
                // TimelineView
                TimelineView()
                
                // TransportView
                TransportView()
                
                Spacer()
            }
        }
    }
}

extension ChordProgressView {
    struct NavigationHeader: View {
        var onClickHome: () -> Void
        var onClickSave: () -> Void
        
        var body: some View {
            HStack {
                Button {
                    onClickHome()
                } label: {
                    Image("home")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                
                Spacer()
                
                Button{
                    onClickSave()
                } label: {
                    Image("download")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
        }
    }
    
    struct ToolbarView: View {
        var onClickTrash: () -> Void
        var onClickUndo: () -> Void
        var onClickRedo: () -> Void
        
        var body: some View {
            HStack {
                HStack(spacing: 20) {
                    Text("6/8")
                    
                    Text("80 BPM")
                        
                    Text("C Key")
                }
                .font(Typography.DOSGothic.M6)
                .foregroundStyle(.text1)
                
                Spacer()
                
                HStack(spacing: 28) {
                    Button {
                        onClickTrash()
                    } label: {
                        Image("trash")
                    }
                    
                    Button {
                        onClickUndo()
                    } label: {
                        Image("undo")
                    }
                    
                    Button {
                        onClickRedo()
                    } label: {
                        Image("redo")
                    }
                }
            }
        }
    }
    
    struct TimelineView: View {
        var body: some View {
            VStack(spacing: 8) {
                MeasureView()
                
                MeasureView()
                
                MeasureView()
                
                MeasureView()
            }
        }
    }
    
    struct MeasureView: View {
        let numerator: Int = 4
        
        private var chordColums: [GridItem] {
            Array(repeating: GridItem(.flexible(), spacing: 0), count: numerator)
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Measure Index
                Text("1")
                    .font(Typography.DOSGothic.M2)
                    .foregroundStyle(.text1)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 1)
                
                VStack(spacing: 0){
                    LazyVGrid(columns: chordColums, spacing: 0) {
                        ChordCellView(
                            chord: .init(root: .A, quality: .min),
                            showsTrailingDivider: true
                        )
                        ChordCellView(
                            chord: .init(root: .A, quality: .maj6),
                            showsTrailingDivider: true
                        )
                        ChordCellView(
                            chord: .init(root: .A, quality: .seven),
                            showsTrailingDivider: true
                        )
                        ChordCellView(
                            chord: .init(root: .A, quality: .maj),
                            isSelected: true,
                            showsTrailingDivider: false
                        )
                    }
                    .overlay(alignment: .bottom) {
                         Rectangle()
                             .fill(Color.black.opacity(0.1))
                             .frame(height: 1)
                     }
                    
                    // Hum wave
                    HumWaveView()
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    struct ChordCellView: View {
        var chord: Chord
        var isSelected: Bool = false
        var showsTrailingDivider: Bool = false

        var body: some View {
            VStack {
                Text("\(chord.description)")
                    .font(Typography.DOSGothic.M10)
                    .foregroundStyle(.text1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 66)
            .background(isSelected ? Color.green2 : Color.clear)
            .contentShape(Rectangle())
            .overlay(alignment: .trailing) {
                if showsTrailingDivider {
                    Rectangle()
                        .fill(.black.opacity(0.1))
                        .frame(width: 1)
                }
            }
        }
    }
    
    struct HumWaveView: View {
        var body: some View {
            HStack {
                Text("Home Wave")
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(.gray1)
        }
    }
    
    struct TransportView: View {
        var body: some View {
            
        }
    }
}

#Preview {
    ChordProgressView()
}
