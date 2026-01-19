//
//  GMGApp.swift
//  GMG
//
//  Created by 나현흠 on 10/17/25.
//

import SwiftUI

@main
struct GMGApp: App {
    @State private var themeManager: ThemeManager = .init()
    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(themeManager)
                .environment(\.palette, themeManager.palette)
        }
    }
}
