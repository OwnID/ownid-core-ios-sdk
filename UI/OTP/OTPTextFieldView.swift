import SwiftUI
import Combine

extension OwnID.UISDK.OneTimePasswordCodeLength {
    var fields: [OwnID.UISDK.OTPViewModel.FieldType] {
        switch self {
        case .four:
            return [.one, .two, .three, .four]
            
        case .six:
            return [.one, .two, .three, .four, .five, .six]
        }
    }
}

extension String {
    var isNumber: Bool {
        let digitsCharacters = CharacterSet(charactersIn: "0123456789")
        return CharacterSet(charactersIn: self).isSubset(of: digitsCharacters)
    }
}

extension OwnID.UISDK.OTPViewModel {
    
    enum FieldType: Identifiable, Hashable {
        static func typeForNumber(_ number: Int) -> Self? {
            switch number {
            case 1:
                return .one
                
            case 2:
                return .two
                
            case 3:
                return .three
                
            case 4:
                return .four
                
            case 5:
                return .five
                
            case 6:
                return .six
                
            default:
                return .none
            }
        }
        
        var id: Self { return self }
        
        var rawValue: Int {
            switch self {
            case .one:
                return 1
                
            case .two:
                return 2
                
            case .three:
                return 3
                
            case .four:
                return 4
                
            case .five:
                return 5
                
            case .six:
                return 6
            }
        }
        
        case one
        case two
        case three
        case four
        case five
        case six
    }
}

extension OwnID.UISDK {
    final class OTPViewModel: ObservableObject {
        init(codeLength: OwnID.UISDK.OneTimePasswordCodeLength,
             store: Store<OwnID.UISDK.OneTimePasswordView.ViewState, OwnID.UISDK.OneTimePasswordView.Action>) {
            self.codeLength = codeLength
            self.store = store
            storage = Array(repeating: "", count: codeLength.rawValue + 1)
        }
        
        let codeLength: OneTimePasswordCodeLength
        
        private let store: Store<OwnID.UISDK.OneTimePasswordView.ViewState, OwnID.UISDK.OneTimePasswordView.Action>
        private var storage: [String]
        
        func onUpdateOf(field: FieldType, value: String) {
            storage[field.rawValue] = value
        }
        
        private func combineCode() -> String {
            let code = storage.reduce("", +)
            return code
        }
        
        func submitCode() {
            let code = combineCode()
            if code.count == codeLength.rawValue {
                store.send(.codeEntered(code))
            }
        }
    }
}

extension OwnID.UISDK {
    @available(iOS 15.0, *)
    public struct OTPTextFieldView: View {
        
        enum NextUpdateAcion {
            case update(String)
            case updatingFromPasteboard
        }
        
        @ObservedObject var viewModel: OTPViewModel
        @FocusState private var focusedField: OwnID.UISDK.OTPViewModel.FieldType?
        private let boxSideSize: CGFloat = 50
        private let spaceBetweenBoxes: CGFloat = 8
        private let cornerRadius = 6.0
        private let characterLimit = 1
        
        @State private var code1 = ""
        @State private var code2 = ""
        @State private var code3 = ""
        @State private var code4 = ""
        @State private var code5 = ""
        @State private var code6 = ""
        @State private var nextUpdateAction: NextUpdateAcion?
        
        public var body: some View {
            HStack(spacing: spaceBetweenBoxes) {
                ForEach(viewModel.codeLength.fields, id: \.self) { field in
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
            //            .onReceive(Just(code6)) { _ in  }
            //            .onReceive(Just(code4)) { _ in  }
            .onChange(of: code1, perform: { newValue in
                processTextChange(for: .one, binding: $code1)
            })
            .onChange(of: code2, perform: { newValue in
                processTextChange(for: .two, binding: $code2)
            })
            .onChange(of: code3, perform: { newValue in
                processTextChange(for: .three, binding: $code3)
            })
            .onChange(of: code4, perform: { newValue in
                processTextChange(for: .four, binding: $code4)
            })
            .onChange(of: code5, perform: { newValue in
                processTextChange(for: .five, binding: $code5)
            })
            .onChange(of: code6, perform: { newValue in
                processTextChange(for: .six, binding: $code6)
            })
            .onAppear() {
                focusedField = .one
            }
        }
        
        func processTextChange(for field: OwnID.UISDK.OTPViewModel.FieldType, binding: Binding<String>) {
            print("field: \(field), \(binding.wrappedValue)")
            if !binding.wrappedValue.isNumber {
                binding.wrappedValue = ""
            }
            if case .updatingFromPasteboard = nextUpdateAction {
                return
            }
            if binding.wrappedValue.count == viewModel.codeLength.rawValue { // paste event of code
                nextUpdateAction = .updatingFromPasteboard
                let fieldValue = binding.wrappedValue
                for index in 0...viewModel.codeLength.rawValue - 1 {
                    if let type = OwnID.UISDK.OTPViewModel.FieldType.typeForNumber(index + 1) {
                        let character = fieldValue.prefix(index + 1).suffix(1)
                        let codeNumber = String(character)
                        switch type {
                        case .one:
                            code1 = codeNumber
                        case .two:
                            code2 = codeNumber
                        case .three:
                            code3 = codeNumber
                        case .four:
                            code4 = codeNumber
                        case .five:
                            code5 = codeNumber
                        case .six:
                            code6 = codeNumber
                        }
                        
                        viewModel.onUpdateOf(field: type, value: codeNumber)
                    }
                }
                viewModel.submitCode()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    nextUpdateAction = .none
                }
                return
            }
            var nextFieldValue = ""
            if binding.wrappedValue.count > characterLimit {
                let current = binding.wrappedValue
                nextFieldValue = String(current.dropFirst(characterLimit).prefix(characterLimit))
                binding.wrappedValue = String(binding.wrappedValue.prefix(characterLimit))
                nextUpdateAction = .update(nextFieldValue)
                return
            }
            viewModel.onUpdateOf(field: field, value: binding.wrappedValue)
            switch field {
            case .one:
                if !code1.isEmpty {
                    focusedField = .two
                    if case .update(let value) = nextUpdateAction {
                        nextUpdateAction = .none
                        code2 = value
                    }
                }
                
            case .two:
                if code2.isEmpty {
                    focusedField = .one
                } else {
                    focusedField = .three
                    if case .update(let value) = nextUpdateAction {
                        nextUpdateAction = .none
                        code3 = value
                    }
                }
                
            case .three:
                if code3.isEmpty {
                    focusedField = .two
                } else {
                    focusedField = .four
                    if case .update(let value) = nextUpdateAction {
                        nextUpdateAction = .none
                        code4 = value
                    }
                }
                
            case .four:
                if code4.isEmpty {
                    focusedField = .three
                } else {
                    if viewModel.codeLength == .four {
                        viewModel.submitCode()
                    } else {
                        focusedField = .five
                        if case .update(let value) = nextUpdateAction {
                            nextUpdateAction = .none
                            code5 = value
                        }
                    }
                }
                
            case .five:
                if code5.isEmpty {
                    focusedField = .four
                } else {
                    focusedField = .six
                    if case .update(let value) = nextUpdateAction {
                        nextUpdateAction = .none
                        code6 = value
                    }
                }
                
            case .six:
                if code6.isEmpty {
                    focusedField = .five
                } else {
                    viewModel.submitCode()
                }
            }
        }
        
        func tileBorderColor(for field: OwnID.UISDK.OTPViewModel.FieldType) -> Color {
            focusedField == field ? OwnID.Colors.otpTileSelectedBorderColor : OwnID.Colors.otpTileBorderColor
        }
        
        func binding(for field: OwnID.UISDK.OTPViewModel.FieldType) -> Binding<String> {
            switch field {
            case .one:
                return $code1
            case .two:
                return $code2
            case .three:
                return $code3
            case .four:
                return $code4
            case .five:
                return $code5
            case .six:
                return $code6
            }
        }
    }
}
