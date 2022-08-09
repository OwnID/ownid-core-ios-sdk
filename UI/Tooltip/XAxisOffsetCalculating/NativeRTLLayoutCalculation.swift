import SwiftUI
import OwnIDCoreSDK

extension OwnID.UISDK {
    struct NativeRTLLayoutCalculation: XAxisOffsetCalculating {
        func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect) -> CGFloat {
            var XOffset = 0.0
            if viewBounds.minX <= screenBounds.minX {
                let XOffsetBounds = screenBounds.minX - viewBounds.minX
                let combinedOffset = XOffsetBounds + defaultXAxisOffset
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
