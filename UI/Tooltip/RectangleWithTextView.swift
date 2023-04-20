import SwiftUI

extension OwnID.UISDK {
    struct RectangleWithTextView: View {
        private let radius: CGFloat = 6
        @State private var isTranslationChanged = false
        
        private let tooltipVisualLookConfig: TooltipVisualLookConfig
        
        init(tooltipVisualLookConfig: TooltipVisualLookConfig) {
            self.tooltipVisualLookConfig = tooltipVisualLookConfig
        }
        
        var body: some View {
            Text(localizedKey: .tooltip)
                .foregroundColor(tooltipVisualLookConfig.textColor)
                .fontWithLineHeight(font: .systemFont(ofSize: tooltipVisualLookConfig.textSize), lineHeight: tooltipVisualLookConfig.lineHeight)
                .onReceive(OwnID.CoreSDK.shared.translationsModule.translationsChangePublisher) {
                    isTranslationChanged.toggle()
                }
                .padding(.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                .background(
                    RoundedRectangle(cornerRadius: radius)
                        .fill(tooltipVisualLookConfig.backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: radius)
                        .stroke(tooltipVisualLookConfig.borderColor, lineWidth: 1)
                )
                .overlay(Text("\(String(isTranslationChanged))").foregroundColor(.clear), alignment: .bottom)
        }
    }
}
