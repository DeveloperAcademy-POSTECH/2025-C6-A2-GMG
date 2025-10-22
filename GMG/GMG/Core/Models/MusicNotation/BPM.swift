//  Copyright © 2025 ADA 4th GMG. All rights reserved.

struct BPM {
    let value: Int
}

extension BPM: CustomStringConvertible {
    var description: String {
        String(describing: value)
    }
}
