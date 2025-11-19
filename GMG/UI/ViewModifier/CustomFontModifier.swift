//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import SwiftUI

struct LocalizedCustomFontModifier: ViewModifier {
    @Environment(\.locale) private var locale: Locale

    private let primary: LocalizedCustomFont
    private let fonts: [LocalizedCustomFont]

    init(primary: LocalizedCustomFont, secondary: [LocalizedCustomFont]) {
        self.primary = primary
        self.fonts = [primary] + secondary
    }

    private var fontToUse: CustomFont {
        guard let currentCode: Locale.LanguageCode = locale.language.languageCode,
            let localizedFont: LocalizedCustomFont = fonts.first(where: {
                $0.languageCode == currentCode
            })
        else { return primary.customFont }
        return localizedFont.customFont
    }

    func body(content: Content) -> some View {
        content
            .font(fontToUse)
    }
}

#Preview {
    VStack {
        Text("English")
            .modifier(
                LocalizedCustomFontModifier(
                    primary: .english(Typography.Pretendard.SB5),
                    secondary: [.korean(Typography.Pretendard.M5)]
                )
            )
            .environment(\.locale, .init(languageCode: .english))
        Text("Korean")
            .modifier(
                LocalizedCustomFontModifier(
                    primary: .english(Typography.Pretendard.SB5),
                    secondary: [.korean(Typography.Pretendard.M5)]
                )
            )
            .environment(\.locale, .init(languageCode: .korean))
    }
}
