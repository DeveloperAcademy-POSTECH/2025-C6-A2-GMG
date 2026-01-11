//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

enum HomePalette {
    enum Background {
        static let root = Color.bg1
    }

    enum Header {
        static let logoRe = Color.black3
        static let logoChord = Color.black1
        static let songCountText = Color.black1
        static let blurTint = UIColor.bg1
    }

    enum Recent {
        static let title = Color.black1
        static let addButtonIcon = Color.black1
        static let addButtonBackground = Color.white
    }

    enum All {
        static let title = Color.black1
        static let sortEnabled = Color.black3
        static let sortDisabled = Color.black5

        static let emptyLine1 = Color.white3.opacity(0.55)
        static let emptyLine2 = Color.black8.opacity(0.3)
        static let emptyLine3 = Color.black4.opacity(0.3)
        static let emptyLine4 = Color.black4.opacity(0.35)
    }

    enum ScoreCard {
        static let title = Color.white1
        static let meta = Color.white1
        static let key = Color.white2
        static let menuIcon = Color.white1

        private static let latestBackgrounds: [Color] = [.blue3, .blue4, .blue5, .blue1, .blue2]
        private static let earliestBackgrounds: [Color] = [.blue2, .blue1, .blue5, .blue4, .blue3]

        static func latestBackground(index: Int) -> Color {
            latestBackgrounds[index % latestBackgrounds.count]
        }

        static func earliestBackground(index: Int) -> Color {
            earliestBackgrounds[index % earliestBackgrounds.count]
        }
    }

    enum Playback {
        static let icon = Color.black1
        static let circleFill = Color.white2
        static let circleBaseStroke = Color.bg1
        static let circleBaseStrokeIdle = Color.white2
        static let progress = Color.bg2
    }
}

extension UIColor {
    enum Home {
        static let headerBlurTint = UIColor.bg1
    }
}
