import SwiftUI
import OwnIDCoreSDK

extension OwnID.UISDK {
    struct ReactNativeLTRLayoutCalculation: XAxisOffsetCalculating {
        func calculateXAxisOffset(viewBounds: CGRect, screenSize: CGRect) -> CGFloat {
            return 0
        }
    }
}
