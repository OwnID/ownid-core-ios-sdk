import SwiftUI
import OwnIDCoreSDK

extension OwnID.UISDK {
    struct NativeLTRLayoutCalculation: XAxisOffsetCalculating {
        func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect) -> CGFloat {
            var XOffset = 0.0
            if viewBounds.maxX >= screenBounds.maxX {
                XOffset = screenBounds.maxX - viewBounds.maxX
            }
            let computedOffset = viewBounds.origin.x + XOffset - defaultXAxisOffset
            return computedOffset
        }
    }
}
