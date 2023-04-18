import SwiftUI
import Combine
extension OwnID.UISDK.OTPViewModel {
    enum FieldType: Identifiable, Hashable {
        var id: Self {
            return self
        }
        
        case one
        case two
        case three
        case four
        case five
        case six
    }
    
    enum State {
        case four
        case six
        
        var fields: [FieldType] {
            switch self {
            case .four:
                return [.one, .two, .three, .four]
                
            case .six:
                return [.one, .two, .three, .four, .five, .six]
            }
        }
    }
}

extension OwnID.UISDK {
    final class OTPViewModel: ObservableObject {
        init(store: Store<OwnID.UISDK.OneTimePasswordView.ViewState, OwnID.UISDK.OneTimePasswordView.Action>) {
            self.store = store
            $code1.map { ($0, FieldType.one) }
                .merge(with: $code2.map { ($0, FieldType.two) })
                .merge(with: $code3.map { ($0, FieldType.three) })
                .merge(with: $code4.map { ($0, FieldType.four) })
                .merge(with: $code5.map { ($0, FieldType.five) })
                .merge(with: $code6.map { ($0, FieldType.six) })
                .sink { (fieldValue, fieldType) in
                    self.onUpdateOf(field: fieldType, value: fieldValue)
                }
                .store(in: &bag)
        }
        
        @Published var state: State = .six
        @Published var code1 = ""
        @Published var code2 = ""
        @Published var code3 = ""
        @Published var code4 = ""
        @Published var code5 = ""
        @Published var code6 = ""
        
        let store: Store<OwnID.UISDK.OneTimePasswordView.ViewState, OwnID.UISDK.OneTimePasswordView.Action>
        private var storage = [FieldType: String]()
        private var bag = Set<AnyCancellable>()
        
        func onUpdateOf(field: FieldType, value: String) {
            storage[field] = value
        }
        
        func combineCode() -> String {
            let code = storage.values.reduce("", +)
            return code
        }
    }
}

extension OwnID.UISDK {
    @available(iOS 15.0, *)
    public struct OTPTextFieldView: View {
        @ObservedObject var viewModel: OTPViewModel
        @FocusState private var focusedField: OwnID.UISDK.OTPViewModel.FieldType?
        let codeLength: OneTimePasswordCodeLength
        private let boxSideSize: CGFloat = 50
        private let spaceBetweenBoxes: CGFloat = 8
        private let cornerRadius = 6.0
        
        public var body: some View {
            HStack(spacing: spaceBetweenBoxes) {
                ForEach(viewModel.state.fields, id: \.self) { field in
                    ZStack {
                        Rectangle()
                            .foregroundColor(OwnID.Colors.otpTileBackgroundColor)
                            .border(tileBorderColor(for: field))
                            .cornerRadius(cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(tileBorderColor(for: field), lineWidth: 1)
                            )
                        
                        TextField("", text: binding(for: field))
                            .font(Font.system(size: 20))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: field)
                            .padding(12)
                    }
                    .frame(width: boxSideSize, height: boxSideSize)
                }
            }
            .onAppear() {
                focusedField = .one
            }
        }
        
        func tileBorderColor(for field: OwnID.UISDK.OTPViewModel.FieldType) -> Color {
            focusedField == field ? OwnID.Colors.otpTileSelectedBorderColor : OwnID.Colors.otpTileBorderColor
        }
        
        func binding(for field: OwnID.UISDK.OTPViewModel.FieldType) -> Binding<String> {
            switch field {
            case .one:
                return $viewModel.code1
            case .two:
                return $viewModel.code2
            case .three:
                return $viewModel.code3
            case .four:
                return $viewModel.code4
            case .five:
                return $viewModel.code5
            case .six:
                return $viewModel.code6
            }
        }
    }
}
