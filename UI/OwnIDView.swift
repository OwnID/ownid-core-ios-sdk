import Foundation
import SwiftUI
import OwnIDCoreSDK

public extension OwnID.UISDK {
    struct OwnIDView: View {
        static func == (lhs: OwnID.UISDK.OwnIDView, rhs: OwnID.UISDK.OwnIDView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        private let isOrViewEnabled: Bool
        private let beakHeight: CGFloat = 8
        private let beakWidth: CGFloat = 14
        private let buttonOffset: CGFloat = 4
        private let textWithRegtangleHeight: CGFloat = 43
        
        private let imageButtonView: ImageButton
        private let coordinateSpaceName = String(describing: OwnID.UISDK.ImageButton.self)
        
        public var eventPublisher: OwnID.UISDK.EventPubliser {
            imageButtonView.eventPublisher
                .eraseToAnyPublisher()
        }
        
        public init(viewState: Binding<ButtonState>, visualConfig: VisualLookConfig) {
            self.imageButtonView = ImageButton(viewState: viewState, visualConfig: visualConfig)
            self.isOrViewEnabled = visualConfig.isOrViewEnabled
        }
        
        public var body: some View {
            HStack(spacing: 8) {
                if isOrViewEnabled {
                    OwnID.UISDK.OrView()
                }
                #warning("move into subviews with content block")
                TooltipContainerLayout {
                    TooltipTextAndArrowLayout {
                        RectangleWithTextView()
                            .popupTextContainerType(.text)
                        BeakView()
                            .popupTextContainerType(.arrow)
                    }
                    .compositingGroup()
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 4)
                    .popupContainerType(.textAndArrowContainer)
                    imageButtonView
                        .layoutPriority(1)
                        .popupContainerType(.button)
                }
            }
        }
    }
}

#warning("move to own file")
struct TooltipContainerLayout: Layout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let buttonSize = subviews.first(where: { $0[TooltipContainerViewTypeKey.self] == .button })?.sizeThatFits(.unspecified) ?? .zero
        return buttonSize
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        guard let textAndArrowContainerSubview = subviews.first(where: { $0[TooltipContainerViewTypeKey.self] == .textAndArrowContainer }) else { return }
        let buttonSize = subviews.first(where: { $0[TooltipContainerViewTypeKey.self] == .button })?.sizeThatFits(.unspecified) ?? .zero
        textAndArrowContainerSubview.place(at: .init(x: bounds.origin.x + (buttonSize.width / 2.5), y: bounds.origin.y - buttonSize.height - 10), proposal: .unspecified)
    }
    
    private func calculateTextSpacingFromScreen(viewFrame: CGRect) -> CGFloat {
        if viewFrame.maxX >= UIScreen.main.bounds.size.width {
            let spacingToScreenSide: CGFloat = 10
            let offsetFromScreenSide = UIScreen.main.bounds.size.width - viewFrame.maxX
            return offsetFromScreenSide - spacingToScreenSide
        }
        return 0
    }
}

#warning("move to own file")
struct TooltipTextAndArrowLayout: Layout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let textViewSize = subviews.first(where: { $0[TooltiptextAndArrowContainerViewTypeKey.self] == .text })?.sizeThatFits(.unspecified) ?? .zero
        return textViewSize
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        guard !subviews.isEmpty else { return }
        guard let textSubview = subviews.first(where: { $0[TooltiptextAndArrowContainerViewTypeKey.self] == .text }) else { return }
        guard let arrowSubview = subviews.first(where: { $0[TooltiptextAndArrowContainerViewTypeKey.self] == .arrow }) else { return }
        let arrowHeight = arrowSubview.sizeThatFits(.unspecified).height
        let textHeight = textSubview.sizeThatFits(.unspecified).height
        let offsetFromScreenSide = calculateTextSpacingFromScreen(viewBounds: bounds)
        let textX = Locale.current.isRTL ? bounds.origin.x - offsetFromScreenSide : bounds.origin.x + offsetFromScreenSide
        let textY = bounds.maxY - arrowHeight - (textHeight / 1.29)
        textSubview.place(at: .init(x: textX, y: textY), proposal: .unspecified)
        arrowSubview.place(at: .init(x: bounds.minX, y: bounds.maxY), proposal: .unspecified)
    }
    
#warning("move to own file")
    private func calculateTextSpacingFromScreen(viewBounds: CGRect) -> CGFloat {
        let spacingToScreenSide: CGFloat = 10
        let nativePlatform = true
        if nativePlatform {
            if Locale.current.isRTL {
                if viewBounds.minX <= UIScreen.main.bounds.minX {
                    print("0")
                    let offsetFromScreenSide = UIScreen.main.bounds.minX - viewBounds.minX
                    let combinedOffset = offsetFromScreenSide + spacingToScreenSide
                    return combinedOffset
                }
            } else {
                if viewBounds.maxX >= UIScreen.main.bounds.maxX {
                    let offsetFromScreenSide = UIScreen.main.bounds.maxX - viewBounds.maxX
                    let combinedOffset = offsetFromScreenSide - spacingToScreenSide
                    return combinedOffset
                }
            }
        } else {
#warning("devide into functions or factory or something")
            if !UIScreen.main.bounds.contains(.init(x: viewBounds.midX / 1.25, y: viewBounds.maxY)) {
                let offsetFromScreenSide = -(viewBounds.midX * 1.25)
                let combinedOffset = Locale.current.isRTL ? offsetFromScreenSide + spacingToScreenSide : offsetFromScreenSide - spacingToScreenSide
                return combinedOffset
            }
            
            if !UIScreen.main.bounds.contains(.init(x: viewBounds.midX / 1.5, y: viewBounds.maxY)) {
                let offsetFromScreenSide = -(viewBounds.midX * 1.5)
                let combinedOffset = offsetFromScreenSide - spacingToScreenSide
                return combinedOffset
            }
            
            if !UIScreen.main.bounds.contains(.init(x: viewBounds.midX / 2, y: viewBounds.maxY)) {
                let offsetFromScreenSide = -(viewBounds.midX / 2)
                let combinedOffset = offsetFromScreenSide - spacingToScreenSide
                return combinedOffset
            }
            
            if !UIScreen.main.bounds.contains(.init(x: viewBounds.midX, y: viewBounds.maxY)) {
                let offsetFromScreenSide = -viewBounds.midX
                let combinedOffset = offsetFromScreenSide - spacingToScreenSide
                return combinedOffset
            }
            
            if !UIScreen.main.bounds.contains(.init(x: viewBounds.maxX, y: viewBounds.maxY)) {
                let offsetFromScreenSide = -viewBounds.maxX
                let combinedOffset = offsetFromScreenSide - spacingToScreenSide
                return combinedOffset
            }
        }
        return 0
    }
}

#warning("move to own file")
enum TooltipContainerViewType {
    case button, textAndArrowContainer
}

enum TooltiptextAndArrowContainerViewType {
    case text, arrow
}

struct TooltipContainerViewTypeKey: LayoutValueKey {
    static let defaultValue: TooltipContainerViewType = .button
}

struct TooltiptextAndArrowContainerViewTypeKey: LayoutValueKey {
    static let defaultValue: TooltiptextAndArrowContainerViewType = .text
}

#warning("move to own file")
extension View {
    func popupContainerType(_ value: TooltipContainerViewType) -> some View {
        layoutValue(key: TooltipContainerViewTypeKey.self, value: value)
    }
    
    func popupTextContainerType(_ value: TooltiptextAndArrowContainerViewType) -> some View {
        layoutValue(key: TooltiptextAndArrowContainerViewTypeKey.self, value: value)
    }
}

#warning("move to own file")
private extension Locale {
    var isRTL: Bool {
        guard let language = language.languageCode else { return false }
        let direction = Locale.Language(identifier: language.identifier).characterDirection
        switch direction {
        case .leftToRight:
            return false
        default:
            return true
        }
    }
}
