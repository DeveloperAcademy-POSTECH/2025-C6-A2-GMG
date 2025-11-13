//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

protocol ExportModelStateProtocol {
    var isSharing: Bool { get }
    var shareItems: [Any] { get }

    var title: String { get }
    var keyDescription: String { get }
    var dateString: String { get }
    var imageName: String { get }
}

protocol ExportModelActionProtocol: AnyObject {
    func prepareSheetExport()
    func prepareAudioExport()
    func updateSharing(_ isSharing: Bool)
}

@Observable
final class ExportModel:
    ExportModelStateProtocol,
    ExportModelActionProtocol
{
    private(set) var isSharing: Bool
    private(set) var shareItems: [Any]

    private let score: Score

    var title: String {
        score.title
    }

    var keyDescription: String {
        "\(score.key.description) Key"
    }

    var dateString: String {
        Self.dateFormatter.string(from: score.createdAt)
    }

    var imageName: String {
        "DummyScore"
    }

    init(score: Score) {
        self.score = score
        self.isSharing = false
        self.shareItems = []
    }

    func prepareSheetExport() {
        if let url = Bundle.main.url(
            forResource: "Sample",
            withExtension: "png"
        ) {
            print("image success")
            self.shareItems = [url]
            self.isSharing = true
        } else {
            print("err: image not found")
        }
    }

    func prepareAudioExport() {
        if let url = Bundle.main.url(
            forResource: "Sample",
            withExtension: "m4a"
        ) {
            print("audio success")
            self.shareItems = [url]
            self.isSharing = true
        } else {
            print("err: audio not found")
        }
    }

    func updateSharing(_ isSharing: Bool) {
        self.isSharing = isSharing
    }
}

extension ExportModel {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy. MM. dd"
        return formatter
    }()
}
