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
        let offsetFromScreenSide = calculateTextSpacingFromScreen(viewFrame: bounds)
        let textX = bounds.origin.x + offsetFromScreenSide
        let textY = bounds.maxY - arrowHeight - (textHeight / 1.29)
        textSubview.place(at: .init(x: textX, y: textY), proposal: .unspecified)
        arrowSubview.place(at: .init(x: bounds.minX, y: bounds.maxY), proposal: .unspecified)
    }
    
    private func calculateTextSpacingFromScreen(viewFrame: CGRect) -> CGFloat {
        let spacingToScreenSide: CGFloat = 10
        
        if !UIScreen.main.bounds.contains(.init(x: viewFrame.midX / 1.5, y: viewFrame.maxY)) {
            let offsetFromScreenSide = -(viewFrame.midX * 1.2)
            let combinedOffset = offsetFromScreenSide - spacingToScreenSide
            return combinedOffset
        }
        
        if !UIScreen.main.bounds.contains(.init(x: viewFrame.midX / 2, y: viewFrame.maxY)) {
            let offsetFromScreenSide = -(viewFrame.midX / 2)
            let combinedOffset = offsetFromScreenSide - spacingToScreenSide
            return combinedOffset
        }
        
        if !UIScreen.main.bounds.contains(.init(x: viewFrame.midX, y: viewFrame.maxY)) {
            let offsetFromScreenSide = -viewFrame.midX
            let combinedOffset = offsetFromScreenSide - spacingToScreenSide
            return combinedOffset
        }
        
        if !UIScreen.main.bounds.contains(.init(x: viewFrame.maxX, y: viewFrame.maxY)) {
            let offsetFromScreenSide = -viewFrame.maxX
            let combinedOffset = offsetFromScreenSide - spacingToScreenSide
            return combinedOffset
        }
        
        if viewFrame.maxX >= UIScreen.main.bounds.size.width {
            let offsetFromScreenSide = UIScreen.main.bounds.size.width - viewFrame.maxX
            let combinedOffset = offsetFromScreenSide - spacingToScreenSide
            return combinedOffset
        }
        return 0
    }
}

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

extension View {
    func popupContainerType(_ value: TooltipContainerViewType) -> some View {
        layoutValue(key: TooltipContainerViewTypeKey.self, value: value)
    }
    
    func popupTextContainerType(_ value: TooltiptextAndArrowContainerViewType) -> some View {
        layoutValue(key: TooltiptextAndArrowContainerViewTypeKey.self, value: value)
    }
}

