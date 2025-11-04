//
//  GMGApp.swift
//  GMG
//
//  Created by 나현흠 on 10/17/25.
//

import SwiftUI
import SwiftData

@main
struct GMGApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [Score.self])
    }
}
