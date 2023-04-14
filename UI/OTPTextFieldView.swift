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
            case field
        }
        @ObservedObject var viewModel: OTPViewModel
        @FocusState private var focusedField: FocusField?
        let codeLength: OneTimePasswordCodeLength
        private let boxSideSize: CGFloat = 50
        private let spaceBetweenBoxes: CGFloat = 8
        private let cornerRadius = 6.0
        
        private var backgroundTextField: some View {
            return TextField("", text: $viewModel.verificationCode)
                .frame(width: 0, height: 0, alignment: .center)
                .font(Font.system(size: 0))
                .accentColor(.clear)
                .foregroundColor(.clear)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .onReceive(Just(viewModel.verificationCode)) { _ in viewModel.limitText(codeLength.rawValue) }
                .focused($focusedField, equals: .field)
                .onAppear() {
                    focusedField = .field
                }
                .padding()
        }
        
        public var body: some View {
            ZStack(alignment: .center) {
                backgroundTextField
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
                            Text(viewModel.getPin(at: index))
                                .font(Font.system(size: 20))
                                .fontWeight(.semibold)
                        }
                        .frame(width: boxSideSize, height: boxSideSize)
                    }
                }
            }
        }
    }
}
