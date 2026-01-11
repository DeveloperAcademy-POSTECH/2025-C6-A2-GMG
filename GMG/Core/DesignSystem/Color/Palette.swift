//  Copyright © 2026 ADA 4th GMG. All rights reserved.

import SwiftUI

enum Palette {
    case basic
    case next
}

extension Palette {

    // MARK: - Surface

    var background: Color {
        switch self {
        case .basic: return .bg1
        case .next: return .bg1
        }
    }

    var sheetBackground: Color {
        switch self {
        case .basic: return .white1
        case .next: return .white1
        }
    }

    // MARK: - Text

    var primaryText: Color {
        switch self {
        case .basic: return .black1
        case .next: return .black1
        }
    }

    var secondaryText: Color {
        switch self {
        case .basic: return .white1
        case .next: return .white1
        }
    }

    var keyLabelText: Color {
        switch self {
        case .basic: return .white2
        case .next: return .white2
        }
    }

    var metaText: Color {
        switch self {
        case .basic: return .black5
        case .next: return .black5
        }
    }

    var secondaryInfoText: Color {
        switch self {
        case .basic: return .black3
        case .next: return .black3
        }
    }

    var disabledText: Color {
        switch self {
        case .basic: return .black7
        case .next: return .black7
        }
    }

    // MARK: - Overlay

    var overlayDimming: Color {
        switch self {
        case .basic: return Color.black.opacity(0.6)
        case .next: return Color.black.opacity(0.6)
        }
    }

    var overlayPrimaryText: Color {
        switch self {
        case .basic: return .white1
        case .next: return .white1
        }
    }

    // MARK: - Status / Indicator

    var statusRecording: Color {
        switch self {
        case .basic: return .red1
        case .next: return .red1
        }
    }

    var statusIdle: Color {
        switch self {
        case .basic: return .black3
        case .next: return .black3
        }
    }

    // MARK: - Waveform

    var waveformBar: Color {
        switch self {
        case .basic: return .black4
        case .next: return .black4
        }
    }

    var waveformBackgroundEdit: Color {
        switch self {
        case .basic: return .black2
        case .next: return .black2
        }
    }

    var waveformBackgroundView: Color {
        switch self {
        case .basic: return .white2
        case .next: return .white2
        }
    }

    var waveformUnfilledEdit: Color {
        switch self {
        case .basic: return .black7
        case .next: return .black7
        }
    }

    var waveformUnfilledView: Color {
        switch self {
        case .basic: return .white3
        case .next: return .white3
        }
    }

    var waveformFilledEdit: Color {
        switch self {
        case .basic: return .white1
        case .next: return .white1
        }
    }

    var waveformFilledView: Color {
        switch self {
        case .basic: return .blue4
        case .next: return .blue4
        }
    }

    // MARK: - Accent

    var fingeringColor: Color {
        switch self {
        case .basic: return .blue3
        case .next: return .blue3
        }
    }

    // MARK: - Controls

    // Sort

    var sortEnabledText: Color {
        switch self {
        case .basic: return .black3
        case .next: return .black3
        }
    }

    var sortDisabledText: Color {
        switch self {
        case .basic: return .black5
        case .next: return .black5
        }
    }

    // Navigation

    var navigationBarTitleText: Color {
        primaryText
    }

    var navigationBarIcon: Color {
        primaryText
    }

    // Indicators

    var pageIndicatorActive: Color {
        switch self {
        case .basic: return .black1
        case .next: return .black1
        }
    }

    var pageIndicatorInactive: Color {
        switch self {
        case .basic: return .black8
        case .next: return .black8
        }
    }

    // Buttons

    var primaryButtonLabel: Color {
        switch self {
        case .basic: return .white1
        case .next: return .white1
        }
    }

    var primaryButtonBackground: Color {
        switch self {
        case .basic: return .black1
        case .next: return .black1
        }
    }

    var secondaryButtonLabel: Color {
        switch self {
        case .basic: return .black1
        case .next: return .black1
        }
    }

    var secondaryButtonBackground: Color {
        switch self {
        case .basic: return .white1
        case .next: return .white1
        }
    }

    // MARK: - Scroll Mask

    var scrollMaskTopStart: Color {
        switch self {
        case .basic: return .clear
        case .next: return .clear
        }
    }

    var scrollMaskTopEnd: Color {
        switch self {
        case .basic: return sheetBackground
        case .next: return sheetBackground
        }
    }

    var scrollMaskBottom: Color {
        switch self {
        case .basic: return sheetBackground
        case .next: return sheetBackground
        }
    }

    // MARK: - Components

    // Sheet

    var sheetHeaderTitleText: Color {
        primaryText
    }

    var sheetHeaderKeyText: Color {
        primaryText
    }

    var chordSegmentBackground: Color {
        switch self {
        case .basic: return .black9
        case .next: return .black9
        }
    }

    // Segment - Chord Candidates

    var chordCandidateSelectedBackground: Color {
        switch self {
        case .basic: return .blue6
        case .next: return .blue6
        }
    }

    var chordCandidatePrimaryBackground: Color {
        switch self {
        case .basic: return .blue7
        case .next: return .blue7
        }
    }

    var chordCandidateSecondaryBackground: Color {
        switch self {
        case .basic: return .blue3
        case .next: return .blue3
        }
    }

    // Segment - Chord Cells

    var chordCellHighlightBackground: Color {
        switch self {
        case .basic: return .blue6
        case .next: return .blue6
        }
    }

    // Time Ruler

    var timeRulerLabelText: Color {
        switch self {
        case .basic: return .black7
        case .next: return .black7
        }
    }

    // ScoreCard

    private static let scoreCardLatestBackgrounds: [Color] = [
        .blue3, .blue4, .blue5, .blue1, .blue2,
    ]
    private static let scoreCardEarliestBackgrounds: [Color] = [
        .blue2, .blue1, .blue5, .blue4, .blue3,
    ]

    static func scoreCardLatestBackground(index: Int) -> Color {
        scoreCardLatestBackgrounds[index % scoreCardLatestBackgrounds.count]
    }

    static func scoreCardEarliestBackground(index: Int) -> Color {
        scoreCardEarliestBackgrounds[index % scoreCardEarliestBackgrounds.count]
    }

    // Playback

    var playbackProgressTrack: Color {
        switch self {
        case .basic: return .bg2
        case .next: return .bg2
        }
    }

    // MARK: - Empty State

    private static let emptyStateLines: [Color] = [
        Color.white3.opacity(0.55),
        Color.black8.opacity(0.3),
        Color.black4.opacity(0.3),
        Color.black4.opacity(0.35),
    ]

    static func emptyStateLineColor(index: Int) -> Color {
        let clampedIndex = max(0, min(index, emptyStateLines.count - 1))
        return emptyStateLines[clampedIndex]
    }
}
