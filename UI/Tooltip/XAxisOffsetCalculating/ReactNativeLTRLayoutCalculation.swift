import SwiftUI
import OwnIDCoreSDK

extension OwnID.UISDK {
    struct ReactNativeLTRLayoutCalculation: XAxisOffsetCalculating {
        let isBottomPosition: Bool
        
        func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect) -> CGFloat {
            let xAndOffetValues = [
                (x: viewBounds.midX / 1.03, operation: viewBounds.midX * 1.03),
                (x: viewBounds.midX / 1.06, operation: viewBounds.midX * 1.06),
                (x: viewBounds.midX / 1.12, operation: viewBounds.midX * 1.12),
                (x: viewBounds.midX / 1.25, operation: viewBounds.midX * 1.25),
                (x: viewBounds.midX / 1.5, operation: viewBounds.midX * 1.5),
                (x: viewBounds.midX / 2, operation: viewBounds.midX / 2),
                (x: viewBounds.midX, operation: viewBounds.midX),
                (x: viewBounds.maxX / 1.44, operation: viewBounds.maxX * 1.44),
                (x: viewBounds.maxX / 1.88, operation: viewBounds.maxX * 1.88),
                (x: viewBounds.maxX, operation: viewBounds.maxX),
                (x: viewBounds.maxX * 1.5, operation: viewBounds.maxX / 1.5)
            ]
            for xAndOffetValue in xAndOffetValues {
                if !screenBounds.contains(.init(x: xAndOffetValue.x, y: viewBounds.maxY)) {
                    let XOffsetBounds = -xAndOffetValue.operation
                    var combinedOffset: CGFloat
                    combinedOffset = screenBounds.origin.x + XOffsetBounds
                    if isBottomPosition {
                        combinedOffset += defaultXAxisOffset
                    }
                    return combinedOffset
                }
            }
            return 0
        }
    }
}
