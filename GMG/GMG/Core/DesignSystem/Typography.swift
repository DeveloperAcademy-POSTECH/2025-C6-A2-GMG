//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

protocol CustomFont {
    static var FontName: String { get }

    var size: CGFloat { get }
    var lineHeightMultiple: CGFloat { get }
}

enum Typography {
    enum DOSGothic: CustomFont {
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

        static let FontName: String = "DOSGothic"

        var size: CGFloat {
            switch self {
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
            }
        }

        var lineHeightMultiple: CGFloat {
            return 1.4
        }
    }

    enum NeoDunggeunmoPro: CustomFont {
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
        case R12
        case R13
        case R14
        case R15

        static let FontName: String = "NeoDunggeunmoPro-Regular"

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
            case .R10: return 26
            case .R11: return 28
            case .R12: return 30
            case .R13: return 32
            case .R14: return 34
            case .R15: return 36
            }
        }

        var lineHeightMultiple: CGFloat {
            return 1.4
        }
    }
}
