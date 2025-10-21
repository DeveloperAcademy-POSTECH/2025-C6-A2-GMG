//  Copyright © 2025 ADA 4th GMG. All rights reserved.

struct TimeSignature {
    let numerator: Int
    let denumerator: NoteDuration

    private init(numerator: Int, denumerator: NoteDuration) {
        self.numerator = numerator
        self.denumerator = denumerator
    }
}

extension TimeSignature {
    static var threeFour: TimeSignature = TimeSignature(
        numerator: 3,
        denumerator: .quarter
    )
    static var fourFour: TimeSignature = TimeSignature(
        numerator: 4,
        denumerator: .quarter
    )
    static var sixEight: TimeSignature = TimeSignature(
        numerator: 6,
        denumerator: .eighth
    )
}

extension TimeSignature: CustomStringConvertible {
    var description: String {
        "\(numerator)/\(denumerator)"
    }
}

extension TimeSignature: CaseIterable {
    static var allCases: [TimeSignature] = [threeFour, fourFour, sixEight]
}
