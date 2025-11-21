//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftUI
internal import UIKit

protocol ExportIntentProtocol {
    func onAppear(_ score: Score)
}

final class ExportIntent: ExportIntentProtocol {
    private(set) var model: ExportModelActionProtocol

    init(model: ExportModelActionProtocol) {
        self.model = model
    }

    func onAppear(_ score: Score) {

        let renderer = ImageRenderer(content: ChordSheetView(score: score))

        if let uiImage = renderer.uiImage {
            model.updateSheetImage(uiImage)

            if let data = uiImage.pngData() {
                let fileName = "sheet-\(score.id.uuidString).png"
                let url = FileManager.default
                    .temporaryDirectory
                    .appendingPathComponent(fileName)

                do {
                    try data.write(to: url)
                    model.updateSheetURL(url)
                } catch {
                    print("error")
                }
            }
        }

        do {
            let renderedURL = try DefaultScoreAudioRenderer(score: score)
                .renderToAudioFile(score: score, fileName: "\(score.title).m4a")
            model.updateAudioURL(renderedURL)
        } catch {
            print("offline render failed: \(error)")
        }
    }
}
