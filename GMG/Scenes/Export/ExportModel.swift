//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftUI

protocol ExportModelStateProtocol {
    var score: Score { get }
    var sheetImages: [UIImage]? { get }
    var sheetImageURLs: [URL]? { get }
    var audioURL: URL? { get }
    var keyDescription: String { get }
    var dateString: String { get }
}

protocol ExportModelActionProtocol: AnyObject {
    func updateSheetImages(_ images: [UIImage]?, _ urls: [URL]?)
    func updateAudioURL(_ url: URL?)
}

@Observable
final class ExportModel:
    ExportModelStateProtocol,
    ExportModelActionProtocol
{
    private(set) var score: Score
    private(set) var sheetImages: [UIImage]?
    private(set) var sheetImageURLs: [URL]?
    private(set) var audioURL: URL?

    var keyDescription: String {
        "\(score.key.description) Key"
    }

    var dateString: String {
        Self.dateFormatter.string(from: .now)
    }

    init(score: Score) {
        self.score = score
        self.sheetImages = nil
        self.sheetImageURLs = nil
        self.audioURL = nil
    }

    func updateSheetImages(_ images: [UIImage]?, _ urls: [URL]?) {
        self.sheetImages = images
        self.sheetImageURLs = urls
    }

    func updateAudioURL(_ url: URL?) {
        self.audioURL = url
    }
}

extension ExportModel {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy. MM. dd"
        return formatter
    }()
}
