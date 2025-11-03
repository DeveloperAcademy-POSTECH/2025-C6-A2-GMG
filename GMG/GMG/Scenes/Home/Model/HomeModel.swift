//  Copyright © 2025 ADA 4th GMG. All rights reserved.

import Foundation

@Observable
class HomeMode: HomeModelStateProtocol, HomeModelActionProtocol {
    private(set) var songCount: Int
    
    init(songCount: Int) {
        self.songCount = songCount
    }
    
    func updateSongCount(_ songCount: Int) {
        self.songCount = songCount
    }
}
