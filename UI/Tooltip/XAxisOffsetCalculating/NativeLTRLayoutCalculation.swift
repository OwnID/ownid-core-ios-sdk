import SwiftUI

extension OwnID.UISDK {
    struct NativeLTRLayoutCalculation: XAxisOffsetCalculating {
        let viewFrame: CGRect
        
        func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect) -> CGFloat {
            var XOffset = 0.0
            if viewBounds.maxX >= screenBounds.maxX {
                XOffset = screenBounds.maxX - viewBounds.maxX
            }
            let computedOffset = viewBounds.origin.x + XOffset - (viewFrame.width / 2)
            return computedOffset
        }
    }
}
