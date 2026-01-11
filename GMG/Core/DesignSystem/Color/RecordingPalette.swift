//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

enum RecordingPalette {

    enum Background {
        static let root = Color.bg1
    }

    enum Countdown {
        static let dimming = Color.black.opacity(0.6)
        static let number = Color.white1
        static let skip = Color.white1
    }

    enum RecordingTime {
        static let indicatorRecording = Color.red1
        static let indicatorIdle = Color.black3

        static let timeBase = Color.black3
        static let timeHighlight = Color.black1
    }

    enum WaveForm {
        static let bar = Color.black4
    }

    enum Loading {
        static let background = Color.bg1
    }

    enum LoadingRow {
        static let active = Color.black1
        static let inactive = Color.black7
    }
}
