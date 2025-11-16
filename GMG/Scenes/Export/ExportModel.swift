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
    func updateShareItems(_ items: [Any])
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

    func updateSharing(_ isSharing: Bool) {
        self.isSharing = isSharing
    }

    func updateShareItems(_ items: [Any]) {
        self.shareItems = items
    }
}

extension ExportModel {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy. MM. dd"
        return formatter
    }()
}
