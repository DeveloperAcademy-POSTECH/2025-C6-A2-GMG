//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

protocol ExportIntentProtocol {
    func onAppear()
}

final class ExportIntent: ExportIntentProtocol {
    private let model: ExportModelActionProtocol

    init(model: ExportModelActionProtocol) {
        self.model = model
    }

    func onAppear() {
        prepareExportURLs()
    }

    private func prepareExportURLs() {
        let sheetURL = Bundle.main.url(
            forResource: "Sample",
            withExtension: "png"
        )

        let audioURL = Bundle.main.url(
            forResource: "Sample",
            withExtension: "m4a"
        )

        model.updateSheetURL(sheetURL)
        model.updateAudioURL(audioURL)
    }
}
