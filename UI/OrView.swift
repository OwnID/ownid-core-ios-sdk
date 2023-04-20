import SwiftUI

extension OwnID.UISDK {
    struct OrView: View {
        @State private var isTranslationChanged = false
        let textSize: CGFloat
        let lineHeight: CGFloat
        let textColor: Color
        
        init(textSize: CGFloat, lineHeight: CGFloat, textColor: Color) {
            self.textSize = textSize
            self.lineHeight = lineHeight
            self.textColor = textColor
        }
        
        var body: some View {
            Text(localizedKey: .or)
                .fontWithLineHeight(font: .systemFont(ofSize: textSize), lineHeight: lineHeight)
                .foregroundColor(textColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .onReceive(OwnID.CoreSDK.shared.translationsModule.translationsChangePublisher) {
                    isTranslationChanged.toggle()
                }
                .overlay(Text("\(String(isTranslationChanged))").foregroundColor(.clear), alignment: .bottom)
        }
    }
}
