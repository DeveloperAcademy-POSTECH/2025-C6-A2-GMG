//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

enum Logger {
    static func error(
        _ message: String,
        file: String = #file,
        line: Int = #line
    ) {
        #if DEBUG
            let fileName = (file as NSString).lastPathComponent
            print("🔴 [ERROR] \(fileName):\(line) - \(message)")
        #endif
    }

    static func warning(
        _ message: String,
        file: String = #file,
        line: Int = #line
    ) {
        #if DEBUG
            let fileName = (file as NSString).lastPathComponent
            print("🟠 [WARNING] \(fileName):\(line) - \(message)")
        #endif
    }

    static func debug(
        _ message: String,
        file: String = #file,
        line: Int = #line
    ) {
        #if DEBUG
            let fileName = (file as NSString).lastPathComponent
            print("🟢 [DEBUG] \(fileName):\(line) - \(message)")
        #endif
    }
}
