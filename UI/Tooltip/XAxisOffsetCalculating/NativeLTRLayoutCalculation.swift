import SwiftUI
import OwnIDCoreSDK

extension OwnID.UISDK {
    struct NativeLTRLayoutCalculation: XAxisOffsetCalculating {
        func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect) -> CGFloat {
            var XOffset = 0.0
            if viewBounds.maxX >= screenBounds.maxX {
                let XOffsetBounds = screenBounds.maxX - viewBounds.maxX
                let combinedOffset = XOffsetBounds - defaultXAxisOffset
                XOffset = combinedOffset
            }
            var computedOffset = viewBounds.origin.x + XOffset
            if XOffset == 0.0 { // means view is in center of screen, visible, so we adjust it to have good position
                computedOffset -= defaultXAxisOffset
            }
            return computedOffset
        }
    }
}
