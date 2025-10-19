//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct SaveWithOptionsView: View {
    @State private var container: SaveWithOptionsContainer

    private var state: SaveWithOptionsState { container.state }

    init(container: SaveWithOptionsContainer = SaveWithOptionsContainer()) {
        self._container = State(wrappedValue: container)
    }

    private var titleBinding: Binding<String> {
        Binding {
            state.title
        } set: {
            container.send(.setTitle(title: $0))
        }
    }

    private var selectedOptionBinding: Binding<SaveOption> {
        Binding {
            state.selectedOption
        } set: {
            container.send(.selectSaveOption(saveOption: $0))
        }
    }

    private var selectedCDStyleBinding: Binding<CDStyle> {
        Binding {
            state.selectedCDStyle
        } set: {
            container.send(.selectCDStyle(cdStyle: $0))
        }
    }

    @State private var isSaveAlertPresented: Bool = false

    var body: some View {
        ZStack {
            Color.backgroundLight1
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 120) {
                    VStack(spacing: Spacing.xxl) {
                        OptionsCarousel(
                            selectedOption: selectedOptionBinding,
                            title: state.title,
                            date: Date(),
                            cdStyle: state.selectedCDStyle
                        )
                        OptionsCarouselIndicator(
                            selectedOption: selectedOptionBinding
                        )
                        
                        TitleTextField(text: titleBinding)
                        
                        CDDesignPickerTitle()
                        CDDesignPicker(selectedCDStyle: selectedCDStyleBinding)
                    }
                    
                    SaveButton(saveAction: {
                        container.send(.save)
                        isSaveAlertPresented = true
                    })
                    .disabled(state.title.isEmpty)
                }
            }
            .contentMargins(.top, Spacing.xl)
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .toastAlert(
            isPresented: $isSaveAlertPresented,
            icon: .download,
            message: "녹음본과 악보가 저장되었어요"
        )
    }

    struct OptionsCarousel: View {
        @Binding var selectedOption: SaveOption

        let title: String
        let date: Date
        let cdStyle: CDStyle

        @State private var scrollViewWidth: CGFloat = .zero
        private let optionWidth: CGFloat = 200

        private var scrollPositionId: Binding<(some Hashable)?> {
            Binding(
                get: {
                    selectedOption as SaveOption?
                },
                set: { option in
                    if let option {
                        selectedOption = option
                    }
                }
            )
        }

        var body: some View {
            ScrollView(.horizontal) {
                LazyHStack(spacing: .zero) {
                    ForEach(SaveOption.allCases, id: \.self) { option in
                        Group {
                            switch option {
                            case .cd:
                                CDCase(
                                    title: title,
                                    date: date,
                                    cdStyle: cdStyle
                                )
                            case .score:
                                // TODO: - 악보 데이터 전달
                                if let image = ChordScore(
                                    title: title,
                                    timeSignature: "4/4",
                                    bpm: 80,
                                    key: "E",
                                    measures: [
                                        ["Am7", "G", "E", "F#m"],
                                        ["C", "E", "Bm", "F#m"],
                                        ["B", nil, "E", nil],
                                        ["C", nil, nil, "D"],
                                        [nil, "G", nil, "Am"],
                                    ]
                                ).uiImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .overlay {
                                            Rectangle()
                                                .strokeBorder(.gray4, lineWidth: 2)
                                        }
                                }
                            case .audioFile:
                                Image(.audioFileIcon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 128)
                            }
                        }
                        .frame(width: optionWidth)
                        .onTapGesture {
                            withAnimation {
                                selectedOption = option
                            }
                        }
                        .id(option)
                        .scrollTransition { effect, phase in
                            effect
                                .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .safeAreaPadding(.horizontal, (scrollViewWidth - optionWidth) / 2)
            .scrollPosition(
                id: scrollPositionId,
                anchor: .center
            )
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .frame(height: 220)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { newValue in
                self.scrollViewWidth = newValue
            }
        }
    }

    struct OptionsCarouselIndicator: View {
        @Binding var selectedOption: SaveOption

        var body: some View {
            HStack(spacing: Spacing.xs) {
                ForEach(SaveOption.allCases, id: \.self) { option in
                    Circle()
                        .fill(selectedOption == option ? .gray3 : .gray2)
                        .frame(width: 8, height: 8)
                        .onTapGesture {
                            withAnimation {
                                selectedOption = option
                            }
                        }
                }
            }
        }
    }

    struct TitleTextField: View {
        @Binding var text: String

        var body: some View {
            VStack {
                TextField(
                    "작업명",
                    text: $text,
                    prompt: Text("작업명").foregroundStyle(.gray4)
                )
                .font(Typography.NeoDonggeunmoPro.R6)
                .foregroundStyle(.text1)
                .multilineTextAlignment(.center)
                
                Rectangle()
                    .fill(.gray4)
                    .frame(height: 1)
            }
            .frame(maxWidth: 180)
        }
    }

    struct CDDesignPickerTitle: View {
        var body: some View {
            Text("CD 디자인 선택하기")
                .font(Typography.NeoDonggeunmoPro.R6)
                .foregroundStyle(.text1)
        }
    }

    struct CDDesignPicker: View {
        @Binding var selectedCDStyle: CDStyle

        var body: some View {
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(CDStyle.allCases, id: \.self) { style in
                        Image(style.imageResource)
                            .resizable()
                            .scaledToFit()
                            .overlay {
                                if selectedCDStyle == style {
                                    Circle()
                                        .strokeBorder(.gray3, lineWidth: 3)
                                        .shadow(radius: 8)
                                }
                            }
                            .id(style)
                            .onTapGesture {
                                withAnimation {
                                    selectedCDStyle = style
                                }
                            }
                    }
                }
            }
            .contentMargins(.horizontal, 16)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .frame(height: 72)
        }
    }

    struct SaveButton: View {
        let saveAction: () -> Void

        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            Button {
                saveAction()
            } label: {
                Text("저장하기")
                    .font(Typography.NeoDonggeunmoPro.R6)
                    .foregroundStyle(.text2)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isEnabled ? .gray7 : .gray6)
                            .strokeBorder(.black.opacity(0.1))
                            .animation(.default, value: isEnabled)
                    }
            }
        }
    }
}

#Preview {
    SaveWithOptionsView()
}
