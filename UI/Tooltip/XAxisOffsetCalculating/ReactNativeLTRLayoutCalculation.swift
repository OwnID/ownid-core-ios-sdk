import SwiftUI

extension OwnID.UISDK {
    struct ReactNativeLTRLayoutCalculation: XAxisOffsetCalculating {
        let viewFrame: CGRect
        
        func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect) -> CGFloat {
            let startingPoint = Int(viewFrame.origin.x)
            let widthAddedPoint = Int(viewFrame.origin.x + viewBounds.width)
            for currentX in startingPoint...widthAddedPoint {
                if !screenBounds.contains(.init(x: CGFloat(currentX), y: viewFrame.maxY)) {
                    let offset = currentX - widthAddedPoint
                    return CGFloat(offset)
                }
            }
            return 0
        }
    }
}
