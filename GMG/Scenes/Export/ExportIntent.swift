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
        model.prepareSheetExport()
    }

    func onTapExportAudio() {
        model.prepareAudioExport()
    }

    func onChangeSharing(_ isSharing: Bool) {
        model.updateSharing(isSharing)
    }
}
