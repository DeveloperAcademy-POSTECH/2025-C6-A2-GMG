//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ExportView: View {
    @State private var isSharing = false
    @State private var shareItems: [Any] = []
    
    var body: some View {
        ZStack{
            Color.Background.bg1.ignoresSafeArea()
            VStack(spacing: 0) {
                Header()
                Title()
                KeyDate()
                Image("DummyScore")
                    .padding(.bottom, 69.5)
                ExportButton(
                    exportSheet: exportSheet,
                    exportAudio: exportAudio
                )
                Spacer()
            }
        }
        .sheet(isPresented: $isSharing) {
            ActivityView(activityItems: shareItems)
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
        var body: some View {
            HStack(spacing: 0) {
                Text("Title 1")
                    .font(Typography.WantedSansStd.B15)
                    .foregroundStyle(Color.black1)
                Spacer()
            }
            .padding(.leading, 17.55)
            .padding(.bottom, 7)
        }
    }
    
    struct KeyDate: View {
        var body: some View {
            HStack (spacing: 0) {
                Text("E Key")
                    .font(Typography.WantedSansStd.R7)
                    .foregroundStyle(Color.black1)
                Spacer()
                Text("25. 11. 05")
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
                    .background(RoundedRectangle(cornerRadius: 18).foregroundStyle(Color.black1))
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
                    .background(RoundedRectangle(cornerRadius: 18).foregroundStyle(Color.black1))
                }
            }
            .padding(.horizontal, 16)
        }
    }
    struct ActivityView: UIViewControllerRepresentable {
        let activityItems: [Any]

        func makeUIViewController(context: Context) -> UIActivityViewController {
            UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        }

        func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
    }
}

extension ExportView {
    func exportSheet() {
        if let image = UIImage(named: "sampleImage") {
            print("image success")
            shareItems = [image]
            isSharing = true
        } else {
            print("err: image not found")
        }
    }

    func exportAudio() {
        if let url = Bundle.main.url(forResource: "sample", withExtension: "m4a") {
            print("audio success")
            shareItems = [url]
            isSharing = true
        } else {
            print("err: audio not found")
        }
    }
}

#Preview {
    ExportView()
}
