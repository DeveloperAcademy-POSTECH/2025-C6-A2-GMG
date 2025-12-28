//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

enum ExportPalette {

    enum Background {
        static let root = Color.bg1
        static let sheet = Color.white1
    }

    enum Navigation {
        static let title = Color.black1
        static let homeIcon = Color.black1
    }

    enum Info {
        static let title = Color.black1
        static let key = Color.black1
        static let date = Color.black5
    }

    enum Carousel {
        static let indicatorActive = Color.black1
        static let indicatorInactive = Color.black8
    }

    enum Button {
        static let primaryText = Color.white1
        static let primaryBackground = Color.black1
    }

    enum Sheet {
        static let background = Color.white1

        enum Header {
            static let title = Color.black1
            static let key = Color.black1
        }

        enum ChordSegment {
            static let text = Color.black1
            static let background = Color.black9
        }

        enum TimeRuler {
            static let text = Color.black7
        }
    }
}
