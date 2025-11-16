//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI
import UIKit
internal import UniformTypeIdentifiers

struct ExportView: View {
    @State private var model: any ExportModelStateProtocol
    @State private var intent: any ExportIntentProtocol

    init(score: Score) {
        let model = ExportModel(score: score)
        self._model = State(initialValue: model)
        self._intent = State(initialValue: ExportIntent(model: model))
    }

    var body: some View {
        ZStack {
            Color.bg1.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header() 필요하면 살리기
                Title(title: model.title)
                KeyDate(
                    keyDescription: model.keyDescription,
                    dateString: model.dateString
                )
                Image(model.imageName)
                    .padding(.bottom, 69.5)
                ExportButton(
                    exportSheet: { intent.onTapExportSheet() },
                    exportAudio: { intent.onTapExportAudio() }
                )
                Spacer()
            }
            .navigationBar(leading: {}, center: {}, trailing: {})
        }
        .sheet(
            isPresented: Binding(
                get: { model.isSharing },
                set: { intent.onChangeSharing($0) }
            )
        ) {
            ActivityView(activityItems: model.shareItems)
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
                Text("Export")
                    .font(Typography.WantedSansStd.R6)
                    .foregroundStyle(Color.black1)
                Spacer()
                Image("Home")
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
        let exportSheet: () -> Void
        let exportAudio: () -> Void

        var body: some View {
            HStack(spacing: 19) {
                Button(action: exportSheet) {
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

                Button(action: exportAudio) {
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
            .padding(.horizontal, 16)
        }
    }

    struct ActivityView: UIViewControllerRepresentable {
        let activityItems: [Any]

        func makeUIViewController(context: Context) -> UIActivityViewController {
            UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: nil
            )
        }

        func updateUIViewController(
            _ controller: UIActivityViewController,
            context: Context
        ) {}
    }
}

//#Preview {
//    ExportView(score: Score)
//}
