import SwiftUI
import Combine
import OwnIDCoreSDK

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
    struct ImageButton: View, Equatable {
        static func == (lhs: OwnID.UISDK.ImageButton, rhs: OwnID.UISDK.ImageButton) -> Bool {
            lhs.id == rhs.id
        }
        
        private let id = UUID()
        
        var visualConfig: VisualLookConfig
        #warning("disabled translations")
//        private let localizationClosure: (() -> String)
//        @State private var translationText = ""
        
        private let highlightedImageSpace = EdgeInsets(top: 6, leading: 7, bottom: 6, trailing: 7)
        private let defaultImageSpace = EdgeInsets(top: 7, leading: 8, bottom: 7, trailing: 8)
        
        /// State that needs to be updated as result to events in SDK
        @Binding var viewState: ButtonState
        
        private let resultPublisher = PassthroughSubject<Void, Never>()
        
        var eventPublisher: OwnID.UISDK.EventPubliser {
            resultPublisher
                .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        init(viewState: Binding<ButtonState>, visualConfig: VisualLookConfig) {
//            let localizationClosure = { "skipPassword".ownIDLocalized() }
            self._viewState = viewState
            self.visualConfig = visualConfig
//            self.localizationClosure = localizationClosure
//            self.translationText = localizationClosure()
        }
        
        var body: some View {
            Button(action: {
                resultPublisher.send(())
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
                .background(backgroundRectangle(color: visualConfig.backgroundColor))
                .border(color: visualConfig.borderColor)
                .shadow(color: shouldDisplayHighlighted ? visualConfig.shadowColor : .clear,
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

private extension OwnID.UISDK.ImageButton {
    
    func buttonStyle() -> OwnID.UISDK.StateableButton<AnyView> {
        return OwnID.UISDK.StateableButton(styleChanged: { isPressedStyle -> AnyView in
            let shouldDisplayHighlighted = shouldDisplayHighlighted(isHighlighted: isPressedStyle)
            let imageName = visualConfig.variant.rawValue
            let image = Image(imageName, bundle: .resourceBundle)
                .renderingMode(.template)
                .foregroundColor(visualConfig.iconColor)
                .padding(shouldDisplayHighlighted ? highlightedImageSpace : defaultImageSpace)
            
            let imagesContainer = ZStack(alignment: .topTrailing) {
                image
                checkmarkView
            }
            let styled = style(view: imagesContainer.eraseToAnyView(), shouldDisplayHighlighted: shouldDisplayHighlighted)
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

private extension View {
    var cornerRadiusValue: CGFloat { 6.0 }
    
    func border(color: Color) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadiusValue)
                    .stroke(color, lineWidth: 0.75)
            )
    }
    
    func backgroundRectangle(color: Color) -> some View {
        RoundedRectangle(cornerRadius: cornerRadiusValue)
            .fill(color)
    }
}
