import SwiftUI
import OwnIDCoreSDK

extension OwnID.UISDK {
    struct RTLLayoutCalculation: XAxisOffsetCalculating {
        let shouldIncludeDefaultOffset: Bool
        
        func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect) -> CGFloat {
            var XOffset = 0.0
            if viewBounds.minX <= screenBounds.minX {
                XOffset = screenBounds.minX - viewBounds.minX
            }
            var computedOffset = viewBounds.origin.x - XOffset
            if shouldIncludeDefaultOffset {
                computedOffset -= defaultXAxisOffset
            }
            return computedOffset
        }
    }
}
