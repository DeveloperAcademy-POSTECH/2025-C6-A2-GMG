//  Copyright © 2026 ADA 4th GMG. All rights reserved.

import SwiftUI

struct Palette {
    // MARK: - Surface
    let background: Color
    let sheetBackground: Color

    // MARK: - Text
    let primaryText: Color
    let secondaryText: Color
    let keyLabelText: Color
    let metaText: Color
    let secondaryInfoText: Color
    let disabledText: Color

    // MARK: - Overlay
    let overlayDimming: Color
    let overlayPrimaryText: Color

    // MARK: - Status / Indicator
    let statusRecording: Color
    let statusIdle: Color

    // MARK: - Waveform
    let waveformBar: Color
    let waveformBackgroundEdit: Color
    let waveformBackgroundView: Color
    let waveformUnfilledEdit: Color
    let waveformUnfilledView: Color
    let waveformFilledEdit: Color
    let waveformFilledView: Color

    // MARK: - Accent
    let fingeringColor: Color

    // MARK: - Controls
    let sortEnabledText: Color
    let sortDisabledText: Color

    // Indicators
    let pageIndicatorActive: Color
    let pageIndicatorInactive: Color

    // Buttons
    let primaryButtonLabel: Color
    let primaryButtonBackground: Color
    let secondaryButtonLabel: Color
    let secondaryButtonBackground: Color

    // MARK: - Scroll Mask
    let scrollMaskTopStart: Color
    let scrollMaskTopEnd: Color
    let scrollMaskBottom: Color

    // MARK: - Components
    let chordSegmentBackground: Color

    // Segment - Chord Candidates
    let chordCandidateSelectedBackground: Color
    let chordCandidatePrimaryBackground: Color
    let chordCandidateSecondaryBackground: Color

    // Segment - Chord Cells
    let chordCellHighlightBackground: Color

    // Time Ruler
    let timeRulerLabelText: Color

    // Playback
    let playbackProgressTrack: Color
}

extension Palette {

    // MARK: - Presets

    static let basic: Palette = .init(
        background: .bg1,
        sheetBackground: .white1,
        primaryText: .black1,
        secondaryText: .white1,
        keyLabelText: .white2,
        metaText: .black5,
        secondaryInfoText: .black3,
        disabledText: .black7,
        overlayDimming: Color.black.opacity(0.6),
        overlayPrimaryText: .white1,
        statusRecording: .red1,
        statusIdle: .black3,
        waveformBar: .black4,
        waveformBackgroundEdit: .black2,
        waveformBackgroundView: .white2,
        waveformUnfilledEdit: .black7,
        waveformUnfilledView: .white3,
        waveformFilledEdit: .white1,
        waveformFilledView: .blue4,
        fingeringColor: .blue3,
        sortEnabledText: .black3,
        sortDisabledText: .black5,
        pageIndicatorActive: .black1,
        pageIndicatorInactive: .black8,
        primaryButtonLabel: .white1,
        primaryButtonBackground: .black1,
        secondaryButtonLabel: .black1,
        secondaryButtonBackground: .white1,
        scrollMaskTopStart: .clear,
        scrollMaskTopEnd: .white1,
        scrollMaskBottom: .white1,
        chordSegmentBackground: .black9,
        chordCandidateSelectedBackground: .blue6,
        chordCandidatePrimaryBackground: .blue7,
        chordCandidateSecondaryBackground: .blue3,
        chordCellHighlightBackground: .blue6,
        timeRulerLabelText: .black7,
        playbackProgressTrack: .bg2
    )

    static let next: Palette = .init(
        background: .bg1,
        sheetBackground: .white1,
        primaryText: .black1,
        secondaryText: .white1,
        keyLabelText: .white2,
        metaText: .black5,
        secondaryInfoText: .black3,
        disabledText: .black7,
        overlayDimming: Color.black.opacity(0.6),
        overlayPrimaryText: .white1,
        statusRecording: .red1,
        statusIdle: .black3,
        waveformBar: .black4,
        waveformBackgroundEdit: .black2,
        waveformBackgroundView: .white2,
        waveformUnfilledEdit: .black7,
        waveformUnfilledView: .white3,
        waveformFilledEdit: .white1,
        waveformFilledView: .blue4,
        fingeringColor: .blue3,
        sortEnabledText: .black3,
        sortDisabledText: .black5,
        pageIndicatorActive: .black1,
        pageIndicatorInactive: .black8,
        primaryButtonLabel: .white1,
        primaryButtonBackground: .black1,
        secondaryButtonLabel: .black1,
        secondaryButtonBackground: .white1,
        scrollMaskTopStart: .clear,
        scrollMaskTopEnd: .white1,
        scrollMaskBottom: .white1,
        chordSegmentBackground: .black9,
        chordCandidateSelectedBackground: .blue6,
        chordCandidatePrimaryBackground: .blue7,
        chordCandidateSecondaryBackground: .blue3,
        chordCellHighlightBackground: .blue6,
        timeRulerLabelText: .black7,
        playbackProgressTrack: .bg2
    )

    // MARK: - Navigation

    var navigationBarTitleText: Color { primaryText }
    var navigationBarIcon: Color { primaryText }

    // MARK: - Components - Sheet

    var sheetHeaderTitleText: Color { primaryText }
    var sheetHeaderKeyText: Color { primaryText }

    // MARK: - ScoreCard

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
