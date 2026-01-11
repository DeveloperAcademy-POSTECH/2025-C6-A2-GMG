//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI
internal import UIKit
internal import UniformTypeIdentifiers

struct ExportView: View {
    @Environment(\.palette) private var palette
    @State private var model: ExportModelStateProtocol
    @State private var intent: ExportIntentProtocol
    private weak var router: Router?

    init(
        model: ExportModelStateProtocol,
        intent: ExportIntentProtocol,
        router: Router? = nil
    ) {
        self.model = model
        self.intent = intent
        self.router = router
    }

    var body: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()

            VStack(spacing: .zero) {
                VStack(spacing: .zero) {
                    Title(title: model.score.title)
                    KeyDate(
                        keyDescription: model.keyDescription,
                        dateString: model.dateString
                    )
                }

                Spacer()

                if let images = model.sheetImages {
                    ImageCarousel(images: images)
                        .padding(.horizontal, -Spacing.md)
                }

                Spacer()

                HStack(spacing: Spacing.md) {
                    if let sheetURLs = model.sheetImageURLs {
                        ExportButton(items: sheetURLs, title: .sheet, image: .export)
                    }
                    if let audioURL = model.audioURL {
                        ExportButton(item: audioURL, title: .audio, image: .export)
                    }
                }
            }
            .padding(Spacing.md)
            .padding(.bottom, Spacing.xxl)
            .navigationBar(
                center: {
                    Text(.export)
                        .font(
                            .english(Typography.WantedSansStd.R6),
                            .korean(Typography.Pretendard.M6)
                        )
                        .foregroundStyle(palette.navigationBarTitleText)
                },
                trailing: {
                    Button {
                        router?.popToRoot()
                    } label: {
                        Image(.home)
                            .renderingMode(.template)
                            .foregroundStyle(palette.navigationBarIcon)
                    }
                }
            )
        }
        .task {
            intent.onAppear(score: model.score)
        }
    }
}

extension ExportView {
    struct Title: View {
        @Environment(\.palette) private var palette
        let title: String

        var body: some View {
            HStack(spacing: 0) {
                Text(title)
                    .font(Typography.WantedSansStd.B15)
                    .foregroundStyle(palette.primaryText)
                Spacer()
            }
        }
    }

    struct KeyDate: View {
        @Environment(\.palette) private var palette
        let keyDescription: String
        let dateString: String

        var body: some View {
            HStack(spacing: 0) {
                Text(keyDescription)
                    .font(Typography.WantedSansStd.R7)
                    .foregroundStyle(palette.primaryText)
                Spacer()
                Text(dateString)
                    .font(Typography.WantedSansStd.R4)
                    .foregroundStyle(palette.metaText)
            }
        }
    }

    struct ImageCarousel: View {
        @Environment(\.palette) private var palette
        let images: [UIImage]

        @State private var focusedImageIndex: Int? = .zero

        private let width: CGFloat = 178
        private let height: CGFloat = 386

        var body: some View {
            VStack(spacing: Spacing.xl) {
                GeometryReader { geometry in
                    let screenWidth: CGFloat = geometry.size.width
                    ScrollView(.horizontal) {
                        HStack(spacing: Spacing.lg) {
                            ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                                Button {
                                    focusedImageIndex = index
                                } label: {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(RoundedRectangle(cornerRadius: 18))
                                }
                                .buttonStyle(.bouncy)
                                .id(index)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollClipDisabled()
                    .scrollIndicators(.hidden)
                    .scrollPosition(id: $focusedImageIndex, anchor: .center)
                    .scrollTargetBehavior(.viewAligned)
                    .scrollBounceBehavior(.basedOnSize)
                    .safeAreaPadding(.horizontal, (screenWidth - width) / 2)
                }
                .frame(height: height)

                HStack {
                    ForEach(images.indices, id: \.self) { index in
                        Circle()
                            .fill(
                                focusedImageIndex == index
                                    ? palette.pageIndicatorActive
                                    : palette.pageIndicatorInactive
                            )
                            .frame(width: 6, height: 6)
                            .onTapGesture {
                                focusedImageIndex = index
                            }
                    }
                }
                .opacity(images.count > 1 ? 1.0 : 0.0)
            }
            .animation(.snappy, value: focusedImageIndex)
        }
    }

    struct ExportButton: View {
        @Environment(\.palette) private var palette
        let items: [URL]
        let title: Text
        let image: ImageResource

        init<S: StringProtocol>(item: URL, title: S, image: ImageResource) {
            self.items = [item]
            self.title = Text(title)
            self.image = image
        }

        init(item: URL, title: LocalizedStringResource, image: ImageResource) {
            self.items = [item]
            self.title = Text(title)
            self.image = image
        }

        init<S: StringProtocol>(items: [URL], title: S, image: ImageResource) {
            self.items = items
            self.title = Text(title)
            self.image = image
        }

        init(items: [URL], title: LocalizedStringResource, image: ImageResource) {
            self.items = items
            self.title = Text(title)
            self.image = image
        }

        var body: some View {
            ShareLink(items: items) {
                HStack(spacing: Spacing.xxs) {
                    title
                        .font(
                            .english(Typography.WantedSansStd.M2),
                            .korean(Typography.Pretendard.M6)
                        )
                        .foregroundStyle(palette.primaryButtonLabel)
                    Image(image)
                        .offset(y: -2)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .foregroundStyle(palette.primaryButtonBackground)
                )
            }
            .buttonStyle(.bouncy)
        }
    }
}

#Preview {
    PreviewContainer { router in
        router.view(.export(score: .mock))
    }
    .environment(\.locale, .init(languageCode: .english))
}
