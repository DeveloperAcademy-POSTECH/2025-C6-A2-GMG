//
//  Font+Extensions.swift
//  GMG
//
//  Created by 나현흠 on 10/18/25.
//

import Foundation
import SwiftUI

extension Font {
    enum GMGText {
        case english
        case korean
        
        var value: String {
            switch self {
            case .english:
                return "DOSGothic"
            case .korean:
                return "neodgm"
            }
        }
    }
    
    static func gmgText(type: GMGText, size: CGFloat) -> Font {
        return .custom(type.value, size: size)
    }
}

// .font(.gmgText(.korean, size: 20) 의 형태로 사용하면 한국어용 폰트
// .font(.gmgText(.english, size: 20) 의 형태로 사용하면 영어용 폰트
