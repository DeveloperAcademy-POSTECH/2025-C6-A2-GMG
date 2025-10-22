//  Copyright © 2025 ADA 4th GMG. All rights reserved.

struct Chord {
    let root: NoteName
    let quality: ChordQuality
}

extension Chord: CustomStringConvertible {
    var description: String {
        "\(root)\(quality.description)"
    }
}
