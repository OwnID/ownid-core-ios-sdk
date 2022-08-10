import SwiftUI
import OwnIDCoreSDK

extension OwnID.UISDK {
    struct RectangleWithTextView: View {
        private let radius: CGFloat = 6
        static func == (lhs: OwnID.UISDK.RectangleWithTextView, rhs: OwnID.UISDK.RectangleWithTextView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()
        
        private let localizationChangedClosure: (() -> String)
        @State private var translationText: String
        
        private let tooltipVisualLookConfig: TooltipVisualLookConfig
        
        init(tooltipVisualLookConfig: TooltipVisualLookConfig) {
            self.tooltipVisualLookConfig = tooltipVisualLookConfig
            let localizationChangedClosure = { "tooltip-ios".ownIDLocalized() }
            self.localizationChangedClosure = localizationChangedClosure
            _translationText = State(initialValue: localizationChangedClosure())
        }
        
        var body: some View {
            Text(translationText)
                .foregroundColor(tooltipVisualLookConfig.textColor)
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
