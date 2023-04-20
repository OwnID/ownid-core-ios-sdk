import Foundation
import SwiftUI

extension OwnID.UISDK {
    struct TextButton: View {
        let visualConfig: OTPViewConfig
        let actionHandler: (() -> Void)
        @Binding var isLoading: Bool
        
        @State private var isTranslationChanged = false
        @Binding private var buttonState: ButtonState
        
        init(visualConfig: OwnID.UISDK.OTPViewConfig,
             actionHandler: @escaping (() -> Void),
             isLoading: Binding<Bool>,
             buttonState: Binding<ButtonState>) {
            self.visualConfig = visualConfig
            self.actionHandler = actionHandler
            self._isLoading = isLoading
            self._buttonState = buttonState
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

private extension OwnID.UISDK.TextButton {
    @ViewBuilder
    func contents() -> some View {
        HStack(alignment: .center, spacing: 15) {
            if isLoading {
                OwnID.UISDK.SpinnerLoaderView(spinnerColor: visualConfig.loaderViewConfig.color,
                                              spinnerBackgroundColor: visualConfig.loaderViewConfig.backgroundColor,
                                              viewBackgroundColor: visualConfig.authButtonConfig.backgroundColor)
            } else {
                Text(localizedKey: .verify)
                    .fontWithLineHeight(font: .systemFont(ofSize: visualConfig.authButtonConfig.textSize, weight: .bold), lineHeight: visualConfig.authButtonConfig.lineHeight)
                    .foregroundColor(visualConfig.authButtonConfig.textColor)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
