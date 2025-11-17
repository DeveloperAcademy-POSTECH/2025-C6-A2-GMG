//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

struct Note {
    let name: NoteName
    let octave: Int
    let startTime: TimeInterval
    let duration: TimeInterval
}

extension Note: Codable {}

extension Note: Hashable {}
