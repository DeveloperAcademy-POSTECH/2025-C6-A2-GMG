//  Copyright © 2025 ADA 4th GMG. All rights reserved.

struct Key {
    let root: NoteName
    let type: KeyType
}

extension Key: CustomStringConvertible {
    var description: String {
        "\(root)\(type)"
    }
}
