import SwiftUI

extension OwnID.UISDK {
    struct RTLLayoutCalculation: XAxisOffsetCalculating {
        let shouldIncludeDefaultOffset: Bool
        let viewFrame: CGRect
        
        func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect) -> CGFloat {
            var offset = viewBounds.origin.x + (viewFrame.width / 2) - viewBounds.width
            if shouldIncludeDefaultOffset {
                offset += defaultXAxisOffset
            }
            return offset
            
        }
    }
}
