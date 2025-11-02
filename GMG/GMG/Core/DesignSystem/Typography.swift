//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

protocol CustomFont {
    var FontName: String { get }
    var size: CGFloat { get }
    var lineHeightMultiple: CGFloat { get }
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

        var FontName: String {
            switch self {
            case .R1, .R2, .R3, .R4, .R5, .R6, .R7, .R8, .R9, .R10, .R11:
                return "WantedSansStd-Regular"
            case .M1, .M2:
                return "WantedSansStd-Medium"
            case .B1, .B2, .B3, .B4, .B5, .B6, .B7, .B8, .B9, .B10, .B11,
                .B12, .B13, .B14, .B15, .B16:
                return "WantedSansStd-Bold"
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
            case .M1: return 8
            case .M2: return 10
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
}
