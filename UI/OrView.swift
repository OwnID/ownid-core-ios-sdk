import SwiftUI

extension OwnID.UISDK {
    struct OrView: View {
        private let localizationChangedClosure: (() -> String)
        @State private var translationText: String
        let textSize: CGFloat
        let lineHeight: CGFloat
        let textColor: Color
        
        init(textSize: CGFloat, lineHeight: CGFloat, textColor: Color) {
            let localizationChangedClosure = { OwnID.CoreSDK.TranslationsSDK.TranslationKey.or.localized() }
            self.localizationChangedClosure = localizationChangedClosure
            _translationText = State(initialValue: localizationChangedClosure())
            self.textSize = textSize
            self.lineHeight = lineHeight
            self.textColor = textColor
        }
        
        var body: some View {
            Text(translationText)
                .fontWithLineHeight(font: .systemFont(ofSize: textSize), lineHeight: lineHeight)
                .foregroundColor(textColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .onReceive(OwnID.CoreSDK.shared.translationsModule.translationsChangePublisher) {
                    translationText = localizationChangedClosure()
                }
        }
    }
}
