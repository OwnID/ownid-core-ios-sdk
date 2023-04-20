import Foundation
import SwiftUI

extension OwnID.UISDK {
    struct AuthButton: View {
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
            .padding(EdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8))
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
    func imageWithLoader() -> some View {
        ZStack {
            variantImage()
                .layoutPriority(1)
                .opacity(isLoading ? 0 : 1)
            OwnID.UISDK.SpinnerLoaderView(spinnerColor: visualConfig.loaderViewConfig.color,
                                          spinnerBackgroundColor: visualConfig.loaderViewConfig.backgroundColor,
                                          viewBackgroundColor: visualConfig.authButtonConfig.backgroundColor)
            .opacity(isLoading ? 1 : 0)
        }
    }
    
    @ViewBuilder
    func contents() -> some View {
        HStack(alignment: .center, spacing: 15) {
            imageWithLoader()
            Text(localizedKey: translationKey)
                .fontWithLineHeight(font: .systemFont(ofSize: visualConfig.authButtonConfig.textSize, weight: .bold), lineHeight: visualConfig.authButtonConfig.lineHeight)
                .foregroundColor(visualConfig.authButtonConfig.textColor)
        }
        .frame(maxWidth: .infinity)
    }
    
    func variantImage() -> some View {
        let image = Image(OwnID.UISDK.IconButtonVariant.faceId.rawValue, bundle: .resourceBundle)
            .resizable()
            .renderingMode(.template)
            .frame(width: visualConfig.authButtonConfig.imageHeight, height: visualConfig.authButtonConfig.imageHeight)
            .foregroundColor(visualConfig.authButtonConfig.iconColor)
        return image
    }
}
