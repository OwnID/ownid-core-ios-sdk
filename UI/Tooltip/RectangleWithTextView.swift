import SwiftUI

extension OwnID.UISDK {
    struct RectangleWithTextView: View {
        private let radius: CGFloat = 6
        private let localizationChangedClosure: (() -> String)
        @State private var translationText: String
        
        private let tooltipVisualLookConfig: TooltipVisualLookConfig
        
        init(tooltipVisualLookConfig: TooltipVisualLookConfig) {
            self.tooltipVisualLookConfig = tooltipVisualLookConfig
            let localizationChangedClosure = { OwnID.CoreSDK.TranslationsSDK.TranslationKey.tooltip.localized() }
            self.localizationChangedClosure = localizationChangedClosure
            _translationText = State(initialValue: localizationChangedClosure())
        }
        
        var body: some View {
            Text(translationText)
                .foregroundColor(tooltipVisualLookConfig.textColor)
                .fontWithLineHeight(font: .systemFont(ofSize: tooltipVisualLookConfig.textSize), lineHeight: tooltipVisualLookConfig.lineHeight)
                .onReceive(OwnID.CoreSDK.shared.translationsModule.translationsChangePublisher) {
                    translationText = localizationChangedClosure()
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
        }
    }
}
