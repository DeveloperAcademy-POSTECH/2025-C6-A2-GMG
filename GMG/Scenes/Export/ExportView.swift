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

                Group {
                    if let sheetImage = model.sheetImages?.first {
                        Image(uiImage: sheetImage)
                            .resizable()
                    } else {
                        Color.white1
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .frame(width: 178, height: 386)

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
        }
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
