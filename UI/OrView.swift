import SwiftUI
import OwnIDCoreSDK

extension OwnID.UISDK {
    struct OrView: View {
        static func == (lhs: OwnID.UISDK.OrView, rhs: OwnID.UISDK.OrView) -> Bool {
            lhs.id == rhs.id
        }
        private let id = UUID()

        private let localizationClosure: (() -> String)
        @State private var translationText: String
        
        init() {
            let localizationClosure = { "or".ownIDLocalized() }
            self.localizationClosure = localizationClosure
            _translationText = State(initialValue: localizationClosure())
        }
        
        var body: some View {
            Text(translationText)
                .fontWithLineHeight(font: .systemFont(ofSize: 16), lineHeight: 24)
                .foregroundColor(OwnID.Colors.textGrey)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .onReceive(OwnID.CoreSDK.shared.translationsModule.translationsChangePublisher) {
                    translationText = localizationClosure()
                }
        }
    }
}
