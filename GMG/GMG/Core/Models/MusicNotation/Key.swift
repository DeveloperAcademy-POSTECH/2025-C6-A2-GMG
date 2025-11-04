//  Copyright © 2025 ADA 4th GMG. All rights reserved.

struct Key: Codable {
    let root: NoteName
}

extension Key: CustomStringConvertible {
    var description: String {
        root.description
    }
}
