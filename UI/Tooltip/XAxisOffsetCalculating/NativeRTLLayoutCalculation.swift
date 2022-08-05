import SwiftUI
import OwnIDCoreSDK

extension OwnID.UISDK {
    struct NativeRTLLayoutCalculation: XAxisOffsetCalculating {
        func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect) -> CGFloat {
            if viewBounds.minX <= screenBounds.minX {
                let offsetFromScreenSide = screenBounds.minX - viewBounds.minX
                let combinedOffset = offsetFromScreenSide + defaultXAxisOffset
                return combinedOffset
            }
            return 0
        }
    }
}
