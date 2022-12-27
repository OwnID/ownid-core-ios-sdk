import SwiftUI
import Combine

public extension OwnID.UISDK {
    struct StateableButton<Content>: ButtonStyle where Content: View {
        public init(styleChanged: @escaping (Bool) -> Content) {
            self.styleChanged = styleChanged
        }
        
        public var styleChanged: (Bool) -> Content
        
        public func makeBody(configuration: Configuration) -> some View {
            return styleChanged(configuration.isPressed)
        }
    }
}

extension OwnID.UISDK {
    /// Represents the call to action button. It also displays the state when the OwnID is activated
    struct BorderAndHighlightButton: View {
        
        var buttonViewConfig: ButtonViewConfig
        private let localizationClosure: (() -> String)
        @State private var translationText = ""
        
        private let highlightedSpace = EdgeInsets(top: 6, leading: 7, bottom: 6, trailing: 7)
        private let defaultSpace = EdgeInsets(top: 7, leading: 8, bottom: 7, trailing: 8)
        
        /// State that needs to be updated as result to events in SDK
        @Binding private var viewState: ButtonState
        private let content: () -> any View
        private let action: () -> Void
        
        init(viewState: Binding<ButtonState>,
             buttonViewConfig: ButtonViewConfig,
             action: @escaping () -> Void,
             content: @escaping () -> any View) {
            let localizationClosure = { "skipPassword".ownIDLocalized() }
            self._viewState = viewState
            self.buttonViewConfig = buttonViewConfig
            self.action = action
            self.content = content
            self.localizationClosure = localizationClosure
            self.translationText = localizationClosure()
        }
        
#warning("disabled translations")
        var body: some View {
            Button(action: {
                action()
            }, label: {
                EmptyView()
            })
            .buttonStyle(buttonStyle())
//            .accessibilityLabel(Text(translationText))
            .onReceive(OwnID.CoreSDK.shared.translationsModule.translationsChangePublisher) {
                translationText = localizationClosure()
            }
        }
        
        @ViewBuilder
        private func style(view: AnyView, shouldDisplayHighlighted: Bool) -> some View {
            view
                .background(backgroundRectangle(color: buttonViewConfig.backgroundColor))
                .border(color: buttonViewConfig.borderColor)
                .shadow(color: shouldDisplayHighlighted ? buttonViewConfig.shadowColor : .clear,
                        radius: cornerRadiusValue,
                        x: 0,
                        y: cornerRadiusValue / 2)
        }
        
        @ViewBuilder
        private var checkmarkView: some View {
            switch viewState {
            case .disabled, .enabled:
                EmptyView()
            case .activated:
                Image("fingerprintEnabled", bundle: .resourceBundle)
                    .padding(.trailing, 4)
                    .padding(.top, 4)
            }
        }
    }
}

private extension OwnID.UISDK.BorderAndHighlightButton {
    
    func buttonStyle() -> OwnID.UISDK.StateableButton<AnyView> {
        return OwnID.UISDK.StateableButton(styleChanged: { isPressedStyle -> AnyView in
            let shouldDisplayHighlighted = shouldDisplayHighlighted(isHighlighted: isPressedStyle)
            let viewsContainer = ZStack(alignment: .topTrailing) {
                content()
                    .padding(shouldDisplayHighlighted ? highlightedSpace : defaultSpace)
                    .eraseToAnyView()
                checkmarkView
            }
            let styled = style(view: viewsContainer.eraseToAnyView(), shouldDisplayHighlighted: shouldDisplayHighlighted)
            let highlightedContainerSpacing = EdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1)
            let container = HStack { styled }
                .padding(shouldDisplayHighlighted ? highlightedContainerSpacing : EdgeInsets())
            let embededView = HStack { container }
                .scaleEffect(0.95)
                .eraseToAnyView()
            return embededView
        })
    }
    
    func shouldDisplayHighlighted(isHighlighted: Bool) -> Bool {
        isHighlighted && viewState == .enabled
    }
}
