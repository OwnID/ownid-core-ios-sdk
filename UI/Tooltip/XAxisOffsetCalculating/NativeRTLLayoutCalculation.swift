import SwiftUI
import OwnIDCoreSDK

extension OwnID.UISDK {
    struct NativeRTLLayoutCalculation: XAxisOffsetCalculating {
        func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect) -> CGFloat {
            var XOffset = 0.0
            if viewBounds.minX <= screenBounds.minX {
                XOffset = screenBounds.minX - viewBounds.minX
            }
            let computedOffset = viewBounds.origin.x - XOffset - defaultXAxisOffset
            return computedOffset
        }
    }
}
