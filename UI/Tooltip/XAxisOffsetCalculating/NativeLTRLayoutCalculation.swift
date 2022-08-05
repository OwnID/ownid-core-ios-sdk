import SwiftUI
import OwnIDCoreSDK

extension OwnID.UISDK {
    struct NativeLTRLayoutCalculation: XAxisOffsetCalculating {
        func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect) -> CGFloat {
            if viewBounds.maxX >= screenBounds.maxX {
                let offsetFromScreenSide = screenBounds.maxX - viewBounds.maxX
                let combinedOffset = offsetFromScreenSide - defaultXAxisOffset
                return combinedOffset
            }
            return 0
        }
    }
}
