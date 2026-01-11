//
//  GMGApp.swift
//  GMG
//
//  Created by 나현흠 on 10/17/25.
//

import SwiftUI

@main
struct GMGApp: App {
    @StateObject private var themeManager = ThemeManager()
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(themeManager)
                .environment(\.palette, themeManager.palette)
        }
    }
}
