import Foundation
import SwiftUI
import OwnIDCoreSDK

extension OwnID.UISDK {
    enum TooltipContainerViewType {
        case button, textAndArrowContainer
    }
    
    enum TooltiptextAndArrowContainerViewType {
        case text, beak
    }
    
    struct TooltipContainerViewTypeKey: LayoutValueKey {
        static let defaultValue: TooltipContainerViewType = .button
    }
    
    struct TooltiptextAndArrowContainerViewTypeKey: LayoutValueKey {
        static let defaultValue: TooltiptextAndArrowContainerViewType = .text
    }
}

extension View {
    func popupContainerType(_ value: OwnID.UISDK.TooltipContainerViewType) -> some View {
        layoutValue(key: OwnID.UISDK.TooltipContainerViewTypeKey.self, value: value)
    }
    
    func popupTextContainerType(_ value: OwnID.UISDK.TooltiptextAndArrowContainerViewType) -> some View {
        layoutValue(key: OwnID.UISDK.TooltiptextAndArrowContainerViewTypeKey.self, value: value)
    }
}
