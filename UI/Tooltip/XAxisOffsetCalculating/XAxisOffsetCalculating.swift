import SwiftUI

protocol XAxisOffsetCalculating {
    func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect) -> CGFloat
}

extension XAxisOffsetCalculating {
    func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect = UIScreen.main.bounds) -> CGFloat {
        return calculateXAxisOffset(viewBounds: viewBounds, screenBounds: screenBounds)
    }
}
