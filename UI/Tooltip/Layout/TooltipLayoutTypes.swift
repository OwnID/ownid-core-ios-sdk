//import Foundation
//import SwiftUI
//
//extension OwnID.UISDK {
//    enum TooltipContainerViewType {
//        case ownIdButton, textAndArrowContainer, dismissButton
//    }
//
//    enum TooltiptextAndArrowContainerViewType {
//        case text, beak
//    }
//
//    @available(iOS 16, *)
//    struct TooltipContainerViewTypeKey: LayoutValueKey {
//        static let defaultValue: TooltipContainerViewType = .ownIdButton
//    }
//
//    @available(iOS 16, *)
//    struct TooltiptextAndArrowContainerViewTypeKey: LayoutValueKey {
//        static let defaultValue: TooltiptextAndArrowContainerViewType = .text
//    }
//}
//
//@available(iOS 16, *)
//extension View {
//    @available(iOS 16.0, *)
//    func popupContainerType(_ value: OwnID.UISDK.TooltipContainerViewType) -> some View {
//        layoutValue(key: OwnID.UISDK.TooltipContainerViewTypeKey.self, value: value)
//    }
//
//    @available(iOS 16.0, *)
//    func popupTextContainerType(_ value: OwnID.UISDK.TooltiptextAndArrowContainerViewType) -> some View {
//        layoutValue(key: OwnID.UISDK.TooltiptextAndArrowContainerViewTypeKey.self, value: value)
//    }
//}
