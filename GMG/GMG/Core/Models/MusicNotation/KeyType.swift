//  Copyright © 2025 ADA 4th GMG. All rights reserved.

enum KeyType {
    case major
    case minor
}

extension KeyType: CustomStringConvertible {
    var description: String {
        switch self {
        case .major: "M"
        case .minor: "m"
        }
    }
}
