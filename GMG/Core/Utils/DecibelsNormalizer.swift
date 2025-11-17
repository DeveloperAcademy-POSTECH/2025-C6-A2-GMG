//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

enum DecibelsNormalizer {
    nonisolated static func normalize(_ dB: Float, dBFloor: Float = -90, dBCeil: Float = -10)
        -> Float
    {
        let clampedDB = min(dBCeil, max(dBFloor, dB))

        // Convert dB to linear amplitude (0..1 where 0 dB -> 1.0)
        let amp = pow(10.0, clampedDB / 20.0)
        let ampFloor = pow(10.0, dBFloor / 20.0)
        let ampCeil = pow(10.0, dBCeil / 20.0)

        // Scale to 0..1
        let normalized = (amp - ampFloor) / (ampCeil - ampFloor)
        return max(0.0, min(1.0, normalized))
    }
}
