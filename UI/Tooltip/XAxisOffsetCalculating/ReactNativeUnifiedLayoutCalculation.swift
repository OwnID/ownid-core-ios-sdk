import SwiftUI
import OwnIDCoreSDK

extension OwnID.UISDK {
    struct ReactNativeUnifiedLayoutCalculation: XAxisOffsetCalculating {
        let isRTL: Bool
        func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect) -> CGFloat {
            let xAndOffetValues = [
                (x: viewBounds.midX / 1.25, operation: viewBounds.midX * 1.25),
                (x: viewBounds.midX / 1.5, operation: viewBounds.midX * 1.5),
                (x: viewBounds.midX / 2, operation: viewBounds.midX / 2),
                (x: viewBounds.midX, operation: viewBounds.midX),
                (x: viewBounds.maxX, operation: viewBounds.maxX)
            ]
            for xAndOffetValue in xAndOffetValues {
                if !screenBounds.contains(.init(x: xAndOffetValue.x, y: viewBounds.maxY)) {
                    let XOffset = -xAndOffetValue.operation
                    let combinedOffset = isRTL ? XOffset + defaultXAxisOffset : XOffset - defaultXAxisOffset
                    return combinedOffset
                }
            }
            return 0
        }
    }
}
