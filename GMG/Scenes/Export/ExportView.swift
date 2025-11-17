//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI
internal import UniformTypeIdentifiers

struct ExportView: View {
    @State private var model: any ExportModelStateProtocol
    @State private var intent: any ExportIntentProtocol
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
            Color.bg1.ignoresSafeArea()
            VStack(spacing: 0) {
                Title(title: model.score.title)
                KeyDate(
                    keyDescription: model.keyDescription,
                    dateString: model.dateString
                )
                Image(model.imageName)
                    .padding(.bottom, 69.5)
                ExportButton(
                    sheetURL: model.sheetURL,
                    audioURL: model.audioURL
                )
                Spacer()
            }
            .navigationBar(leading: {}, center: {}, trailing: {})
        }
        .onAppear {
            intent.onAppear()
        }
    }
}

extension ExportView {
    struct Header: View {
        var body: some View {
            HStack(spacing: 0) {
                Image(systemName: "chevron.left")
                    .frame(width: 15)
                Spacer()
                Text(.export)
                    .font(Typography.WantedSansStd.R6)
                    .foregroundStyle(Color.black1)
                Spacer()
                Image(.home)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15)
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 46)
        }
    }

    struct Title: View {
        let title: String

        var body: some View {
            HStack(spacing: 0) {
                Text(title)
                    .font(Typography.WantedSansStd.B15)
                    .foregroundStyle(Color.black1)
                Spacer()
            }
            .padding(.leading, 17.55)
            .padding(.bottom, 7)
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
            .padding(.horizontal, 17.55)
            .padding(.bottom, 34.5)
        }
    }

    struct ExportButton: View {
        let sheetURL: URL?
        let audioURL: URL?

        var body: some View {
            HStack(spacing: 19) {

                if let sheetURL {
                    ShareLink(item: sheetURL) {
                        HStack(spacing: 4) {
                            Text("sheet")
                                .font(Typography.WantedSansStd.M2)
                                .foregroundStyle(Color.white1)
                            Image("Export")
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .foregroundStyle(Color.black1)
                        )
                    }
                }

                if let audioURL {
                    ShareLink(item: audioURL) {
                        HStack(spacing: 4) {
                            Text("Audio")
                                .font(Typography.WantedSansStd.M2)
                                .foregroundStyle(Color.white1)
                            Image("Export")
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
            .padding(.horizontal, 16)
        }
    }
}

//#Preview {
//    ExportView(score: Score)
//}
