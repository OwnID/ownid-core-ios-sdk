import SwiftUI

extension OwnID.UISDK {
    struct ReactNativeLTRLayoutCalculation: XAxisOffsetCalculating {
        let isBottomPosition: Bool
        let viewFrame: CGRect
        #warning("remove textViewWidth?")
        let textViewWidth: CGFloat
        
        func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect) -> CGFloat {
            let startingPoint = Int(viewFrame.origin.x)
            let widthAddedPoint = Int(viewFrame.origin.x + textViewWidth)
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
