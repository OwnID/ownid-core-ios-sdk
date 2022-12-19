import SwiftUI

extension OwnID.UISDK {
    struct RTLLayoutCalculation: XAxisOffsetCalculating {
        let viewFrame: CGRect
        let isStartPosition: Bool
        let isNative: Bool
        
        func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect) -> CGFloat {
            if isNative, isStartPosition {
                let xOffset = viewFrame.width / 2
                return xOffset
            }
            if isStartPosition {
                let xOffset = -(viewBounds.width - (viewFrame.width / 2))
                return xOffset
            }
            let xOffset = viewBounds.origin.x + (viewFrame.width / 2) - viewBounds.width
            return xOffset
            
        }
    }
}
