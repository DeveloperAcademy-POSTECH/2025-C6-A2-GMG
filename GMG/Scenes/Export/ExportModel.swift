//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation
import SwiftUI

protocol ExportModelStateProtocol {

    var score: Score { get }
    var sheetImage: UIImage? { get }
    var audioURL: URL? { get }
    var sheetURL: URL? { get }
    var keyDescription: String { get }
    var dateString: String { get }
    var imageName: String { get }
}

protocol ExportModelActionProtocol: AnyObject {
    func updateSheetImage(_ image: UIImage?)
    func updateAudioURL(_ url: URL?)
    func updateSheetURL(_ url: URL?)
    func readScore(_ perform: (Score) -> Void)
}

@Observable
final class ExportModel:
    ExportModelStateProtocol,
    ExportModelActionProtocol
{

    private(set) var score: Score
    private(set) var sheetImage: UIImage?
    private(set) var audioURL: URL?
    private(set) var sheetURL: URL?

    var keyDescription: String {
        "\(score.key.description) Key"
    }

    var dateString: String {
        Self.dateFormatter.string(from: .now)
    }

    var imageName: String {
        "DummyScore"
    }

    init(score: Score) {
        self.score = score
        self.sheetImage = nil
        self.audioURL = nil
        self.sheetURL = nil
    }

    func updateSheetImage(_ image: UIImage?) {
        self.sheetImage = image
    }

    func updateAudioURL(_ url: URL?) {
        self.audioURL = url
    }

    func updateSheetURL(_ url: URL?) {
        self.sheetURL = url
    }

    func readScore(_ perform: (Score) -> Void) {
        perform(score)
    }
}

extension ExportModel {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy. MM. dd"
        return formatter
    }()
}
