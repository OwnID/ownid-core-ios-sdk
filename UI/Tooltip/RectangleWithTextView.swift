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
        
        init() {
            let localizationChangedClosure = { "tooltip-ios".ownIDLocalized() }
            self.localizationChangedClosure = localizationChangedClosure
            _translationText = State(initialValue: localizationChangedClosure())
        }
        
        var body: some View {
            Text(translationText)
                .onReceive(OwnID.CoreSDK.shared.translationsModule.translationsChangePublisher) {
                    translationText = localizationChangedClosure()
                }
                .padding(.init(top: 10, leading: 16, bottom: 10, trailing: 16))
                .background(
                    RoundedRectangle(cornerRadius: radius)
                        .fill(OwnID.Colors.biometricsButtonBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: radius)
                        .stroke(OwnID.Colors.biometricsButtonBorder, lineWidth: 1)
                )
        }
    }
}
