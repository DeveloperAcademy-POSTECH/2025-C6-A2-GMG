//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

enum Instrument {
    case piano
    case guitar
}

extension Instrument {
    var soundfontFileName: String {
        return switch self {
        case .piano: "KAWAI good piano"
        case .guitar: "Guitar Acoustic"
        }
    }
}

extension Instrument {
    func next() -> Instrument {
        return switch self {
        case .piano: .guitar
        case .guitar: .piano
        }
    }
}

extension Instrument {
    var symbol: ImageResource {
        return switch self {
        case .piano: .piano
        case .guitar: .guitar
        }
    }
}

extension Instrument {
    var octave: Int {
        return switch self {
        case .piano: 2
        case .guitar: 3
        }
    }
}
