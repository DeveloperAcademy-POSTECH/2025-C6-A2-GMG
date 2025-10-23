import SwiftUI

struct ChordProgressView: View {
    private let transportHeight: CGFloat = 162
    @State private var isPlaying = false
    
    var body: some View {
        GeometryReader { proxy in
            let transportHeightWithoutSafeArea = transportHeight - proxy.safeAreaInsets.bottom
            
            ZStack {
                Color.backgroundLight1.ignoresSafeArea()

                VStack(spacing: 0) {
                    NavigationHeader(onClickHome: {}, onClickSave: {})
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 24)

                    ToolbarView(onClickTrash: {}, onClickUndo: {}, onClickRedo: {})
                        .padding(.horizontal, 16)
                        .padding(.bottom, 18)

                    ZStack(alignment: .bottom) {
                        ScrollView(.vertical, showsIndicators: false) {
                            TimelineView()
                                .padding(.bottom, transportHeightWithoutSafeArea)
                        }
                        
                        TransportView(
                            transportHeight: transportHeightWithoutSafeArea,
                            isPlaying: $isPlaying,
                            onClickPlay: { isPlaying = true },
                            onClickPause: { isPlaying = false },
                            onClickStop: { isPlaying = false }
                        )
                    }
                }
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
                    Text("4/4")
                    
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
        var transportHeight: CGFloat
        @Binding var isPlaying: Bool

        var onClickPlay: () -> Void
        var onClickPause: () -> Void
        var onClickStop: () -> Void

        init(
            transportHeight: CGFloat,
            isPlaying: Binding<Bool>,
            onClickPlay: @escaping () -> Void = {},
            onClickPause: @escaping () -> Void = {},
            onClickStop: @escaping () -> Void = {}
        ) {
            self.transportHeight = transportHeight
            self._isPlaying = isPlaying
            self.onClickPlay = onClickPlay
            self.onClickPause = onClickPause
            self.onClickStop = onClickStop
        }

        var body: some View {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.backgroundLight1)
                    .frame(height: 30)
                    .blur(radius: 6)
                    .offset(y: 20)
                
                if !isPlaying {
                    RecommendedChordCellView()
                }

                VStack {
                    TransportPrimaryButton(
                        title: isPlaying ? "일시정지" : "재생하기",
                        action: isPlaying ? onClickPause : onClickPlay
                    )
                    .padding(.top, 23)
                    .padding(.bottom, 18)

                    TransportSecondaryButton(
                        title: "중지",
                        action: onClickStop
                    )
                    .opacity(isPlaying ? 1 : 0)
                    .accessibilityHidden(!isPlaying)
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .frame(maxWidth: .infinity, minHeight: transportHeight, alignment: .top)
            .padding(.top, 10)
            .background(.backgroundLight1)
        }
    }
    
    struct TransportPrimaryButton: View {
        var title: String
        var action: () -> Void

        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(Typography.NeoDonggeunmoPro.R6)
                    .foregroundStyle(.text1)
                    .frame(width: 112, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
            }
        }
    }

    struct TransportSecondaryButton: View {
        var title: String
        var action: () -> Void

        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(Typography.NeoDonggeunmoPro.R5)
                    .foregroundStyle(.text1)
            }
        }
    }
    
    struct RecommendedChordCellView: View {
        var recommendedChords: [Chord] = [
            .init(root: .A, quality: .eleven)
            , .init(root: .G, quality: .sus4)
            , .init(root: .G, quality: .maj)
            , .init(root: .E, quality: .maj)
            , .init(root: .F, quality: .maj)
        ]
        
        var body: some View {
            VStack(spacing: 10) {
                HStack(spacing: 0) {
                    Text("Recommended Chords")
                        .font(Typography.DOSGothic.M6)
                        .foregroundStyle(.text1)
                    Image(systemName: "wand.and.sparkles.inverse")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 10) {
                    ForEach(recommendedChords.indices, id: \.self) { index in
                        Text(recommendedChords[index].description)
                            .font(Typography.DOSGothic.M7)
                            .foregroundStyle(.text1)
                            .frame(width: 64, height: 43)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.green3)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.black.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    ChordProgressView()
}
