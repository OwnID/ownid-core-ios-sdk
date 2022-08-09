import SwiftUI

protocol XAxisOffsetCalculating {
    func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect) -> CGFloat
}

extension XAxisOffsetCalculating {
    #warning("maybe it is interfirs with global position of the to container?")
    var defaultXAxisOffset: CGFloat { 10 }
    func calculateXAxisOffset(viewBounds: CGRect, screenBounds: CGRect = UIScreen.main.bounds) -> CGFloat {
        return calculateXAxisOffset(viewBounds: viewBounds, screenBounds: screenBounds)
    }
}
