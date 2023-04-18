import SwiftUI
import Combine

extension OwnID.UISDK {
    final class OTPViewModel: ObservableObject {
        init(store: Store<OwnID.UISDK.OneTimePasswordView.ViewState, OwnID.UISDK.OneTimePasswordView.Action>) {
            self.store = store
        }
        
        @Published var verificationCode = ""
        let store: Store<OwnID.UISDK.OneTimePasswordView.ViewState, OwnID.UISDK.OneTimePasswordView.Action>
        
        func getPin(at index: Int) -> String {
            guard verificationCode.count > index else {
                return ""
            }
            return String(Array(verificationCode)[index])
        }
        
        func limitText(_ upper: Int) {
            if verificationCode.count == upper {
                store.send(.codeEntered(verificationCode))
            }
            if verificationCode.count > upper {
                verificationCode = String(verificationCode.prefix(upper))
            }
        }
    }
}

extension OwnID.UISDK {
    @available(iOS 15.0, *)
    public struct OTPTextFieldView: View {
        enum FocusField: Hashable {
            case one
            case two
            case three
            case four
            case five
            case six
        }
        @ObservedObject var viewModel: OTPViewModel
        @FocusState private var focusedField: FocusField?
        let codeLength: OneTimePasswordCodeLength
        private let boxSideSize: CGFloat = 50
        private let spaceBetweenBoxes: CGFloat = 8
        private let cornerRadius = 6.0
        
        public var body: some View {
            HStack(spacing: spaceBetweenBoxes) {
                ForEach(0..<codeLength.rawValue, id: \.self) { index in
                    ZStack {
                        Rectangle()
                            .foregroundColor(OwnID.Colors.otpTileBackgroundColor)
                            .border(OwnID.Colors.otpTileBorderColor)
                            .cornerRadius(cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(Color.gray.opacity(0.7), lineWidth: 1)
                            )
                        TextField(viewModel.getPin(at: index), text: .constant(""))
                            .font(Font.system(size: 20))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
//                            .fontWeight(.semibold)
                    }
                    .frame(width: boxSideSize, height: boxSideSize)
                }
            }
        }
    }
}
