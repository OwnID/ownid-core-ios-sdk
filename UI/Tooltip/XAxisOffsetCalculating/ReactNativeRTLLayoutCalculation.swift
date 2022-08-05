import SwiftUI
import OwnIDCoreSDK

extension OwnID.UISDK {
    struct ReactNativeRTLLayoutCalculation: XAxisOffsetCalculating {
        func calculateXAxisOffset(viewBounds: CGRect, screenSize: CGRect) -> CGFloat {
            return 0
        }
    }
}
