//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftUI
internal import UIKit

protocol ExportIntentProtocol {
    func onAppear(score: Score)
}

final class ExportIntent: ExportIntentProtocol {
    private(set) var model: ExportModelActionProtocol

    init(model: ExportModelActionProtocol) {
        self.model = model
    }

    func onAppear(score: Score) {
        let segmentDuration: TimeInterval = 5
        let segments = ChordInSegment.convert(score: score, segmentDuration: segmentDuration)

        let segmentCount: Int = 5
        let images: [UIImage] = stride(from: 0, to: segments.count, by: segmentCount).compactMap {
            index in
            return ChordSheetView(
                title: score.title,
                key: score.key,
                segmentStartTime: TimeInterval(index) * segmentDuration,
                segmentDuration: segmentDuration,
                segments: Array(segments[index..<min(segments.count, index + segmentCount)])
            )
            .uiImage
        }

        let imageURLs: [URL] = images.enumerated().compactMap { index, image in
            guard let data = image.pngData() else { return nil }

            let fileName = "\(score.title)-\(index + 1).png"
            let url = URL.temporaryDirectory.appending(component: fileName)

            do {
                try data.write(to: url)

                return url
            } catch {
                Logger.error("Failed to save sheet image")

                return nil
            }
        }

        model.updateSheetImages(images, imageURLs)

        do {
            let renderer: ScoreAudioRenderer = DefaultScoreAudioRenderer(score: score)
            let renderedURL: URL = try renderer.renderToAudioFile()
            model.updateAudioURL(renderedURL)
        } catch {
            print("offline render failed: \(error)")
        }
    }
}
