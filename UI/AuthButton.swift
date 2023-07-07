import Foundation
import SwiftUI

extension OwnID.UISDK {
    struct AuthButton: View {
        private enum Constants {
            static let buttonSideInset = 8.0
            static let contentsSpacing = 15.0
        }
        
        let visualConfig: VisualLookConfig
        let actionHandler: (() -> Void)
        @Binding var isLoading: Bool
        
        @State private var isTranslationChanged = false
        @Binding private var buttonState: ButtonState
        private let translationKey: OwnID.CoreSDK.TranslationsSDK.TranslationKey
        
        init(visualConfig: OwnID.UISDK.VisualLookConfig,
             actionHandler: @escaping (() -> Void),
             isLoading: Binding<Bool>,
             buttonState: Binding<ButtonState>,
             translationKey: OwnID.CoreSDK.TranslationsSDK.TranslationKey = .continue) {
            self.visualConfig = visualConfig
            self.actionHandler = actionHandler
            self._isLoading = isLoading
            self._buttonState = buttonState
            self.translationKey = translationKey
        }
        
        var body: some View {
            Button(action: actionHandler) {
                contents()
            }
            .disabled(!buttonState.isEnabled)
            .frame(height: visualConfig.authButtonConfig.height)
            .padding(EdgeInsets(top: 0, leading: Constants.buttonSideInset, bottom: 0, trailing: Constants.buttonSideInset))
            .background(backgroundRectangle(color: visualConfig.authButtonConfig.backgroundColor))
            .cornerRadius(cornerRadiusValue)
            .onReceive(OwnID.CoreSDK.shared.translationsModule.translationsChangePublisher) {
                isTranslationChanged.toggle()
            }
            .overlay(Text("\(String(isTranslationChanged))").foregroundColor(.clear), alignment: .bottom)
        }
    }
}

private extension OwnID.UISDK.AuthButton {
    @ViewBuilder
    func contents() -> some View {
        ZStack {
            OwnID.UISDK.SpinnerLoaderView(spinnerColor: visualConfig.loaderViewConfig.color,
                                          spinnerBackgroundColor: visualConfig.loaderViewConfig.backgroundColor,
                                          viewBackgroundColor: visualConfig.authButtonConfig.backgroundColor)
            .frame(width: visualConfig.authButtonConfig.loaderHeight, height: visualConfig.authButtonConfig.loaderHeight)
            .opacity(isLoading ? 1 : 0)
            Text(localizedKey: translationKey)
                .fontWithLineHeight(font: .systemFont(ofSize: visualConfig.authButtonConfig.textSize, weight: .medium), lineHeight: visualConfig.authButtonConfig.lineHeight)
                .foregroundColor(visualConfig.authButtonConfig.textColor)
                .opacity(isLoading ? 0 : 1)
        }
        .frame(maxWidth: .infinity)
    }
}
