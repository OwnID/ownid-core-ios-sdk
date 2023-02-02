import Foundation
import SwiftUI

extension OwnID.UISDK {
    struct AuthButton: View {
        let visualConfig: VisualLookConfig
        let actionHandler: (() -> Void)
        @Binding var isLoading: Bool
        
        private let localizationChangedClosure: (() -> String)
        @State private var translationText: String
        @Binding private var buttonState: ButtonState
        
        init(visualConfig: OwnID.UISDK.VisualLookConfig,
             actionHandler: @escaping (() -> Void),
             isLoading: Binding<Bool>,
             buttonState: Binding<ButtonState>) {
            let localizationChangedClosure = { OwnID.CoreSDK.TranslationsSDK.TranslationKey.continue.localized() }
            self.localizationChangedClosure = localizationChangedClosure
            _translationText = State(initialValue: localizationChangedClosure())
            self.visualConfig = visualConfig
            self.actionHandler = actionHandler
            self._isLoading = isLoading
            self._buttonState = buttonState
        }
        
        var body: some View {
            Button(action: actionHandler) {
                ZStack {
                    contents()
                        .layoutPriority(1)
                        .opacity(isLoading ? 0 : 1)
                    OwnID.UISDK.SpinnerLoaderView(spinnerColor: visualConfig.loaderViewConfig.color,
                                                  spinnerBackgroundColor: visualConfig.loaderViewConfig.backgroundColor,
                                                  viewBackgroundColor: visualConfig.authButtonConfig.backgroundColor)
                    .opacity(isLoading ? 1 : 0)
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(!buttonState.isEnabled)
            .padding(EdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8))
            .background(visualConfig.authButtonConfig.backgroundColor)
            .cornerRadius(6)
            .onReceive(OwnID.CoreSDK.shared.translationsModule.translationsChangePublisher) {
                translationText = localizationChangedClosure()
            }
        }
    }
}

private extension OwnID.UISDK.AuthButton {
    @ViewBuilder
    func contents() -> some View {
        HStack(alignment: .center, spacing: 8) {
            variantImage()
            Text(translationText)
                .fontWithLineHeight(font: .systemFont(ofSize: visualConfig.authButtonConfig.textSize, weight: .bold), lineHeight: visualConfig.authButtonConfig.lineHeight)
                .foregroundColor(visualConfig.authButtonConfig.textColor)
        }
    }
    
    func variantImage() -> some View {
        let image = Image(OwnID.UISDK.IconButtonVariant.faceId.rawValue, bundle: .resourceBundle)
            .renderingMode(.template)
            .foregroundColor(visualConfig.authButtonConfig.iconColor)
        return image
    }
}
