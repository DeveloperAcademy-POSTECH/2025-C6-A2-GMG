//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

enum ProgressPalette {

    // MARK: - 전체 배경 (ChordProgressView.Background)

    enum Background {
        static let normal = Color.bg1
        static let edit = Color.bg2
    }

    // MARK: - 네비게이션 / 타이틀

    enum Navigation {
        static let homeLight = Color.black1
        static let homeDark = Color.white1
    }

    enum Title {
        static let fieldTextLight = Color.black1
        static let fieldTextDark = Color.white1

        static let labelTextLight = Color.black4
        static let labelTextDark = Color.black3

        static let pencilLight = Color.black1
        static let pencilDark = Color.white1

        static let editingBackgroundLight = Color.white3
        static let editingBackgroundDark = Color.black7
    }

    enum ScoreInformation {
        static let normal = Color.black1
        static let edit = Color.white1
    }

    // MARK: - Edit Controller / Edit Mode Toggle

    enum EditController {
        static let enabled = Color.white1
        static let disabled = Color.black2
    }

    enum EditModeToggle {
        static let background = Color.white1

        static let titleSelected = Color.white1
        static let titleUnselected = Color.black1

        static let selectedBackground = Color.blue6
    }

    // MARK: - Fingering (ChordFingeringView / GuitarFingeringView)

    enum Fingering {

        enum ChordBackground {
            static let piano = Color.black8.opacity(0.2)
            static let guitar = Color.white1.opacity(0.7)
        }

        enum Symbol {
            static let light = Color.black1
            static let dark = Color.white1
        }

        enum GuitarStringIndicator {
            static let text = Color.black1
        }

        enum Nut {
            static let fill = Color.black1
        }

        enum String {
            static let mute = Color.red1
            static let normal = Color.black1
        }

        enum FretDivider {
            static let line = Color.black8
        }

        enum Dot {
            static let fill = Color.blue3
        }

        enum Barre {
            static let fill = Color.blue3
        }

        enum FretIndicator {
            static let text = Color.black1
        }

        enum Preview {
            static let background = Color.white1
        }
    }

    // MARK: - Segment / Chord Cells

    enum Segment {

        enum CandidateStrip {
            static let background = Color.black2
        }

        enum CandidateButton {
            static let selectedBackground = Color.blue6
            static let primaryBackground = Color.blue7
            static let secondaryBackground = Color.blue3
            static let title = Color.white1
        }

        enum ChordCellForeground {
            static let editSelected = Color.white1
            static let editCurrent = Color.black1
            static let editNormal = Color.white1

            static let viewCurrent = Color.white1
            static let viewNormal = Color.black1
        }

        enum ChordCellBackground {
            static let editSelected = Color.blue6
            static let editCurrent = Color.white1
            static let editNormal = Color.black2

            static let viewCurrent = Color.blue6
            static let viewNormal = Color.white1
        }

        enum TimeRuler {
            static let edit = Color.black5
            static let view = Color.black8
        }
    }

    // MARK: - Waveform

    enum Waveform {
        static let backgroundEdit = Color.black2
        static let backgroundView = Color.white2

        static let unfilledEdit = Color.black7
        static let unfilledView = Color.white3

        static let filledEdit = Color.white1
        static let filledView = Color.blue4
    }

    // MARK: - SegmentsScrollView Mask

    enum SegmentsScrollMask {
        static let topGradientStart = Color.clear
        static let topGradientEnd = Color.white
        static let bottom = Color.white
    }
}
