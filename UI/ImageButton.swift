import SwiftUI
import Combine
import OwnIDCoreSDK

fileprivate struct StateableButton<Content>: ButtonStyle where Content: View {
    var styleChanged: (Bool) -> Content
    
    func makeBody(configuration: Configuration) -> some View {
        return styleChanged(configuration.isPressed)
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
        
        private let localizationClosure: (() -> String)
        @State private var translationText = ""
        
        private let highlightedImageSpace = EdgeInsets(top: 6, leading: 7, bottom: 6, trailing: 7)
        private let defaultImageSpace = EdgeInsets(top: 7, leading: 8, bottom: 7, trailing: 8)
        
        /// State that needs to be updated as result to events in SDK
        @Binding var viewState: ButtonState
        
        private let resultPublisher = PassthroughSubject<Void, Never>()
        
        var eventPublisher: OwnID.UISDK.EventPubliser {
            resultPublisher
                .delay(for: 1, scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        init(viewState: Binding<ButtonState>, visualConfig: VisualLookConfig) {
            let localizationClosure = { "skipPassword".ownIDLocalized() }
            self._viewState = viewState
            self.visualConfig = visualConfig
            self.localizationClosure = localizationClosure
            self.translationText = localizationClosure()
        }
        
        var body: some View {
            Button(action: {
                resultPublisher.send(())
            }, label: {
                EmptyView()
            })
                .buttonStyle(StateableButton(styleChanged: { isPressedStyle -> AnyView in
                    let shouldDisplayHighlighted = shouldDisplayHighlighted(isHighlighted: isPressedStyle)
                    let biometricsImage = Image("biometricsImage", bundle: .module)
                        .renderingMode(.template)
                        .foregroundColor(visualConfig.biometryIconColor)
                        .padding(shouldDisplayHighlighted ? highlightedImageSpace : defaultImageSpace)
                    
                    let imagesContainer = ZStack(alignment: .topTrailing) {
                        biometricsImage
                        checkmarkView
                    }
                    let styled = style(view: imagesContainer.eraseToAnyView(), shouldDisplayHighlighted: shouldDisplayHighlighted)
                    let highlightedContainerSpacing = EdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1)
                    let container = HStack { styled }
                        .padding(shouldDisplayHighlighted ? highlightedContainerSpacing : .init(.zero))
                    let embededView = HStack { container }.eraseToAnyView()
                    return embededView
                }))
                .accessibilityLabel(Text(translationText))
                .onReceive(OwnID.CoreSDK.shared.translationsModule.translationsChangePublisher) {
                    translationText = localizationClosure()
                }
        }
        
        private func style(view: AnyView, shouldDisplayHighlighted: Bool) -> some View {
            let visualBackgroundColor = visualConfig.backgroundColor
            var viewWithBorder: AnyView = view
                .background(backgroundRectangle(color: visualBackgroundColor))
                .border(color: visualConfig.borderColor)
                .eraseToAnyView()
            if shouldDisplayHighlighted {
                viewWithBorder = viewWithBorder.shadow(shadowColor: visualConfig.shadowColor,
                                                       backgroundColor: visualBackgroundColor).eraseToAnyView()
            }
            return viewWithBorder
        }
        
        @ViewBuilder
        private var checkmarkView: some View {
            switch viewState {
            case .disabled, .enabled:
                EmptyView()
            case .activated:
                Image("fingerprintEnabled", bundle: .module)
                    .padding(.trailing, 4)
                    .padding(.top, 4)
            }
        }
    }
}

private extension OwnID.UISDK.ImageButton {
    func shouldDisplayHighlighted(isHighlighted: Bool) -> Bool {
        isHighlighted && viewState == .enabled
    }
}

private extension View {
    var cornerRadiusValue: CGFloat {
        6.0
    }
    
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
    
    func shadow(shadowColor: Color, backgroundColor: Color) -> some View {
        self
            .background(backgroundRectangle(color: backgroundColor)
                            .shadow(color: shadowColor,
                                    radius: cornerRadiusValue,
                                    x: 0,
                                    y: cornerRadiusValue / 2)
            )
    }
}
