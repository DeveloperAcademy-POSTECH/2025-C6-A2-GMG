//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftUI
internal import UIKit

protocol ExportIntentProtocol {
    func onAppear()
}

final class ExportIntent: ExportIntentProtocol {
    private(set) var model: ExportModelActionProtocol

    init(model: ExportModelActionProtocol) {
        self.model = model
    }

    func onAppear() {
        model.readScore { score in
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

            let service = AudioRenderingService()
            do {
                let renderedURL = try service.renderToAudioFile(score: score)
                model.updateAudioURL(renderedURL)
            } catch {
                print("offline render failed: \(error)")
            }
        }
    }
}
