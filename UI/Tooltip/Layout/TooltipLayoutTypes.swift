import Foundation
import SwiftUI

extension OwnID.UISDK {
    enum TooltipContainerViewType {
        case ownIdButton, textAndArrowContainer, dismissButton
    }
    
    enum TooltiptextAndArrowContainerViewType {
        case text, beak
    }
    
    struct TooltipContainerViewTypeKey: LayoutValueKey {
        static let defaultValue: TooltipContainerViewType = .ownIdButton
    }
    
    struct TooltiptextAndArrowContainerViewTypeKey: LayoutValueKey {
        static let defaultValue: TooltiptextAndArrowContainerViewType = .text
    }
}
