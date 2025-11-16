//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

protocol ExportIntentProtocol {
    func onTapExportSheet()
    func onTapExportAudio()
    func onChangeSharing(_ isSharing: Bool)
}

final class ExportIntent: ExportIntentProtocol {
    private let model: ExportModelActionProtocol

    init(model: ExportModelActionProtocol) {
        self.model = model
    }

    func onTapExportSheet() {
        guard let url = Bundle.main.url(forResource: "Sample", withExtension: "png") else { return }

        model.updateShareItems([url])
        model.updateSharing(true)
    }

    func onTapExportAudio() {
        guard let url = Bundle.main.url(forResource: "Sample", withExtension: "m4a") else { return }

        model.updateShareItems([url])
        model.updateSharing(true)
    }

    func onChangeSharing(_ isSharing: Bool) {
        model.updateSharing(isSharing)
    }
}
