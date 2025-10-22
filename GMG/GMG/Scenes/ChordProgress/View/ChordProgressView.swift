import SwiftUI

struct ChordProgressView: View {
    var body: some View {
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
                .foregroundStyle(Color.text1)
                
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
            }
        }
    }
    
    struct MeasureView: View {
        let numerator: Int = 6
        
        private var chordColums: [GridItem] {
            Array(repeating: GridItem(.flexible(), spacing: 0), count: numerator)
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Measure Index
                Text("1")
                    .font(Typography.DOSGothic.M2)
                    .foregroundStyle(Color.text1)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 1)
                
                // Chod List
                LazyVGrid(columns: chordColums) {
                    ChordCellView()
                    ChordCellView()
                    ChordCellView()
                    ChordCellView()
                    ChordCellView()
                    ChordCellView()
                }
                .border(.red)
                .frame(width: .infinity)
                
                
                // Hum wave
                HumWaveView()
            }
        }
    }
    
    struct ChordCellView: View {
        var body: some View {
            VStack {
                Text("1")
            }
            .frame(height: 66)
        }
    }
    
    struct HumWaveView: View {
        var body: some View {
            HStack {
                Text("Home Wave")
            }
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
