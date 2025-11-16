//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

protocol ExportModelStateProtocol {

    var title: String { get }
    var keyDescription: String { get }
    var dateString: String { get }
    var imageName: String { get }

    var sheetURL: URL? { get }
    var audioURL: URL? { get }
}

protocol ExportModelActionProtocol: AnyObject {
    func updateSheetURL(_ url: URL?)
    func updateAudioURL(_ url: URL?)
}

@Observable
final class ExportModel:
    ExportModelStateProtocol,
    ExportModelActionProtocol
{

    private let score: Score

    private(set) var sheetURL: URL?
    private(set) var audioURL: URL?

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
        self.sheetURL = nil
        self.audioURL = nil
    }

    func updateSheetURL(_ url: URL?) {
        self.sheetURL = url
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
