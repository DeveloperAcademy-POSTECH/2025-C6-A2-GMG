//  Copyright © 2025 ADA 4th GMG. All rights reserved.

enum SaveWithOptionsIntent {
    case setTitle(title: String)
    case selectSaveOption(saveOption: SaveOption)
    case selectCDStyle(cdStyle: CDStyle)
    case save
}
