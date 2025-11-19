//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

protocol CustomFont {
    var font: Font { get }
    var fontName: String { get }
    var size: CGFloat { get }
    var lineHeightMultiple: CGFloat { get }
}

struct LocalizedCustomFont {
    let languageCode: Locale.LanguageCode
    let customFont: CustomFont

    init(_ languageCode: Locale.LanguageCode, _ customFont: CustomFont) {
        self.languageCode = languageCode
        self.customFont = customFont
    }

    static func english(_ font: CustomFont) -> LocalizedCustomFont {
        .init(.english, font)
    }

    static func korean(_ font: CustomFont) -> LocalizedCustomFont {
        .init(.korean, font)
    }
}

enum Typography {
    enum WantedSansStd: CustomFont {
        case R1
        case R2
        case R3
        case R4
        case R5
        case R6
        case R7
        case R8
        case R9
        case R10
        case R11
        case M1
        case M2
        case B1
        case B2
        case B3
        case B4
        case B5
        case B6
        case B7
        case B8
        case B9
        case B10
        case B11
        case B12
        case B13
        case B14
        case B15
        case B16

        static let Regular: String = "WantedSansStd-Regular"
        static let Medium: String = "WantedSansStd-Medium"
        static let SemiBold: String = "WantedSansStd-SemiBold"
        static let Bold: String = "WantedSansStd-Bold"
        static let ExtraBold: String = "WantedSansStd-ExtraBold"
        static let Black: String = "WantedSansStd-Black"
        static let ExtraBlack: String = "WantedSansStd-ExtraBlack"

        var font: Font {
            return Font.custom(self.fontName, size: self.size)
        }

        var fontName: String {
            switch self {
            case .R1, .R2, .R3, .R4, .R5, .R6, .R7, .R8, .R9, .R10, .R11:
                return Self.Regular
            case .M1, .M2:
                return Self.Medium
            case .B1, .B2, .B3, .B4, .B5, .B6, .B7, .B8, .B9, .B10, .B11,
                .B12, .B13, .B14, .B15, .B16:
                return Self.Bold
            }
        }

        var size: CGFloat {
            switch self {
            case .R1: return 8
            case .R2: return 10
            case .R3: return 12
            case .R4: return 14
            case .R5: return 16
            case .R6: return 18
            case .R7: return 20
            case .R8: return 22
            case .R9: return 24
            case .R10: return 34
            case .R11: return 84
            case .M1: return 14
            case .M2: return 18
            case .B1: return 8
            case .B2: return 10
            case .B3: return 12
            case .B4: return 14
            case .B5: return 16
            case .B6: return 18
            case .B7: return 20
            case .B8: return 22
            case .B9: return 24
            case .B10: return 26
            case .B11: return 28
            case .B12: return 30
            case .B13: return 32
            case .B14: return 34
            case .B15: return 36
            case .B16: return 46
            }
        }

        var lineHeightMultiple: CGFloat {
            switch self {
            case .B16: return 1.1
            default: return 1.4
            }
        }
    }

    enum Pretendard: CustomFont {
        case R1
        case M1
        case M2
        case M3
        case M4
        case M5
        case M6
        case M7
        case M8
        case M9
        case M10
        case M11
        case M12
        case M13
        case M14
        case M15
        case M16
        case SB1
        case SB2
        case SB3
        case SB4
        case SB5
        case SB6
        case SB7

        static let Thin: String = "Pretendard-Thin"
        static let ExtraLight: String = "Pretendard-ExtraLight"
        static let Light: String = "Pretendard-Light"
        static let Regular: String = "Pretendard-Regular"
        static let Medium: String = "Pretendard-Medium"
        static let SemiBold: String = "Pretendard-SemiBold"
        static let Bold: String = "Pretendard-Bold"
        static let ExtraBold: String = "Pretendard-ExtraBold"
        static let Black: String = "Pretendard-Black"

        var font: Font {
            return Font.custom(self.fontName, size: self.size)
        }

        var fontName: String {
            switch self {
            case .R1:
                return Self.Regular
            case .M1, .M2, .M3, .M4, .M5, .M6, .M7, .M8,
                .M9, .M10, .M11, .M12, .M13, .M14, .M15, .M16:
                return Self.Medium
            case .SB1, .SB2, .SB3, .SB4, .SB5, .SB6, .SB7:
                return Self.SemiBold
            }
        }

        var size: CGFloat {
            switch self {
            case .R1: return 14
            case .M1: return 8
            case .M2: return 10
            case .M3: return 12
            case .M4: return 14
            case .M5: return 16
            case .M6: return 18
            case .M7: return 20
            case .M8: return 22
            case .M9: return 24
            case .M10: return 26
            case .M11: return 28
            case .M12: return 30
            case .M13: return 32
            case .M14: return 34
            case .M15: return 36
            case .M16: return 38
            case .SB1: return 8
            case .SB2: return 10
            case .SB3: return 12
            case .SB4: return 14
            case .SB5: return 16
            case .SB6: return 18
            case .SB7: return 20
            }
        }

        var lineHeightMultiple: CGFloat {
            switch self {
            default: return 1.4
            }
        }
    }
}
