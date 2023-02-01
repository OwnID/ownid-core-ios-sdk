import Foundation
import SwiftUI

extension OwnID.UISDK {
    struct AuthButton: View {
        init(visualConfig: OwnID.UISDK.VisualLookConfig,
             actionHandler: @escaping (() -> Void)) {
            let localizationChangedClosure = { OwnID.CoreSDK.TranslationsSDK.TranslationKey.continue.localized() }
            self.localizationChangedClosure = localizationChangedClosure
            _translationText = State(initialValue: localizationChangedClosure())
            self.visualConfig = visualConfig
            self.actionHandler = actionHandler
        }
        
        let visualConfig: VisualLookConfig
        let actionHandler: (() -> Void)
        
        private let localizationChangedClosure: (() -> String)
        @State private var translationText: String
        
        var body: some View {
            Button(action: actionHandler) {
                HStack(alignment: .center, spacing: 8) {
                    variantImage()
                    Text(translationText)
                        .fontWithLineHeight(font: .systemFont(ofSize: visualConfig.authButtonConfig.textSize, weight: .bold), lineHeight: visualConfig.authButtonConfig.lineHeight)
                        .foregroundColor(visualConfig.authButtonConfig.textColor)
                        .multilineTextAlignment(.center)
                        .frame(
                            minWidth: 0,
                            maxWidth: .infinity,
                            alignment: .center
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(EdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8))
            .background(visualConfig.authButtonConfig.backgroungColor)
            .cornerRadius(6)
            .onReceive(OwnID.CoreSDK.shared.translationsModule.translationsChangePublisher) {
                translationText = localizationChangedClosure()
            }
        }
    }
}

private extension OwnID.UISDK.AuthButton {
    func variantImage() -> some View {
        let image = Image(OwnID.UISDK.IconButtonVariant.faceId.rawValue, bundle: .resourceBundle)
            .renderingMode(.template)
            .foregroundColor(visualConfig.authButtonConfig.iconColor)
        return image
    }
}
