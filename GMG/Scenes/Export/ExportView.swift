//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI
internal import UIKit
internal import UniformTypeIdentifiers

struct ExportView: View {
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
            Color.bg1
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
                        .foregroundStyle(Color.black1)
                },
                trailing: {
                    Button {
                        router?.popToRoot()
                    } label: {
                        Image(.home)
                            .renderingMode(.template)
                            .foregroundStyle(Color.black1)
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
        let title: String

        var body: some View {
            HStack(spacing: 0) {
                Text(title)
                    .font(Typography.WantedSansStd.B15)
                    .foregroundStyle(Color.black1)
                Spacer()
            }
        }
    }

    struct KeyDate: View {
        let keyDescription: String
        let dateString: String

        var body: some View {
            HStack(spacing: 0) {
                Text(keyDescription)
                    .font(Typography.WantedSansStd.R7)
                    .foregroundStyle(Color.black1)
                Spacer()
                Text(dateString)
                    .font(Typography.WantedSansStd.R4)
                    .foregroundStyle(Color.black5)
            }
        }
    }

    struct ImageCarousel: View {
        let images: [UIImage]

        @State private var focusedImageIndex: Int? = .zero
        @State private var screenWidth: CGFloat = .zero

        private let width: CGFloat = 178
        private let height: CGFloat = 386

        var body: some View {
            VStack(spacing: Spacing.xl) {
                ScrollView(.horizontal) {
                    HStack(spacing: Spacing.lg) {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollPosition(id: $focusedImageIndex, anchor: .center)
                .scrollTargetBehavior(.viewAligned)
                .scrollBounceBehavior(.basedOnSize)
                .safeAreaPadding(.horizontal, (screenWidth - width) / 2)
                .frame(height: height)
                .onGeometryChange(for: CGFloat.self) { geometry in
                    geometry.size.width
                } action: { newValue in
                    self.screenWidth = newValue
                }

                HStack {
                    ForEach(images.indices, id: \.self) { index in
                        Circle()
                            .fill(focusedImageIndex == index ? Color.black1 : Color.black8)
                            .frame(width: 6, height: 6)
                            .onTapGesture {
                                withAnimation {
                                    focusedImageIndex = index
                                }
                            }
                    }
                }
                .opacity(images.count > 1 ? 1.0 : 0.0)
            }
        }
    }

    struct ExportButton: View {
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
                        .foregroundStyle(Color.white1)
                    Image(image)
                        .offset(y: -2)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .foregroundStyle(Color.black1)
                )
            }
        }
    }
}

#Preview {
    PreviewContainer { router in
        router.view(.export(score: .mock))
    }
    .environment(\.locale, .init(languageCode: .english))
}
