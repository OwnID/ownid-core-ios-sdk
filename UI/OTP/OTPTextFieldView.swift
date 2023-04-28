import SwiftUI
import Combine

@available(iOS 15.0, *)
extension OwnID.UISDK.OneTimePassword.CodeLength {
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

@available(iOS 15.0, *)
extension OwnID.UISDK.OTPViewModel {
    enum NextUpdateAcion: Equatable {
        case update(String)
        case updatingFromPasteboard
        case addEmptySpace
    }
    
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
    @available(iOS 15.0, *)
    final class OTPViewModel: ObservableObject {
        init(codeLength: OwnID.UISDK.OneTimePassword.CodeLength,
             store: Store<OwnID.UISDK.OneTimePassword.ViewState, OwnID.UISDK.OneTimePassword.Action>) {
            self.codeLength = codeLength
            self.store = store
            storage = Array(repeating: "", count: codeLength.rawValue + 1)
        }
        
        let codeLength: OwnID.UISDK.OneTimePassword.CodeLength
        
        private let store: Store<OwnID.UISDK.OneTimePassword.ViewState, OwnID.UISDK.OneTimePassword.Action>
        private var storage: [String]
        
        private let characterLimit = 1
        private static let zeroWidthSpaceCharacter = "\u{200B}"
        
        @Published var code1 = zeroWidthSpaceCharacter
        @Published var code2 = zeroWidthSpaceCharacter
        @Published var code3 = zeroWidthSpaceCharacter
        @Published var code4 = zeroWidthSpaceCharacter
        @Published var code5 = zeroWidthSpaceCharacter
        @Published var code6 = zeroWidthSpaceCharacter
        @Published var nextUpdateAction: NextUpdateAcion?
        
        @Published var currentFocusedField: OwnID.UISDK.OTPViewModel.FieldType?
        
        private func onUpdateOf(field: FieldType, value: String) {
            storage[field.rawValue] = value
        }
        
        private func combineCode() -> String {
            let code = storage.reduce("", +)
            return code
        }
        
        private func submitCode() {
            let code = combineCode()
            if code.count == codeLength.rawValue {
                store.send(.codeEntered(code))
            }
        }
        
        func processTextChange(for field: OwnID.UISDK.OTPViewModel.FieldType, binding: Binding<String>) {
            let currentBindingValue = binding.wrappedValue
            let actualValue = currentBindingValue.replacingOccurrences(of: OTPViewModel.zeroWidthSpaceCharacter, with: "")
            if !actualValue.isNumber {
                binding.wrappedValue = OTPViewModel.zeroWidthSpaceCharacter
            }
            let nextActionIsAddZero = nextUpdateAction == OwnID.UISDK.OTPViewModel.NextUpdateAcion.addEmptySpace
            if actualValue.isEmpty, !nextActionIsAddZero {
                binding.wrappedValue = OTPViewModel.zeroWidthSpaceCharacter
                nextUpdateAction = .addEmptySpace
                focusOnNextLeftField(field: field)
                return
            }
            if nextActionIsAddZero {
                nextUpdateAction = .none
            }
            if case .updatingFromPasteboard = nextUpdateAction {
                return
            }
            if actualValue.count == codeLength.rawValue { // paste event of code
                nextUpdateAction = .updatingFromPasteboard
                let fieldValue = actualValue
                for index in 0...codeLength.rawValue - 1 {
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
                        
                        onUpdateOf(field: type, value: codeNumber)
                    }
                }
                submitCode()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.nextUpdateAction = .none
                }
                return
            }
            var nextFieldValue = ""
            if actualValue.count > characterLimit {
                let current = actualValue
                nextFieldValue = String(current.dropFirst(characterLimit).prefix(characterLimit))
                binding.wrappedValue = String(actualValue.prefix(characterLimit))
                nextUpdateAction = .update(nextFieldValue)
                return
            }
            onUpdateOf(field: field, value: actualValue)
            switch field {
            case .one:
                if !actualValue.isEmpty {
                    currentFocusedField = .two
                    if case .update(let value) = nextUpdateAction {
                        nextUpdateAction = .none
                        code2 = value
                    }
                }
                
            case .two:
                if actualValue.isEmpty {
                    currentFocusedField = .one
                } else {
                    currentFocusedField = .three
                    if case .update(let value) = nextUpdateAction {
                        nextUpdateAction = .none
                        code3 = value
                    }
                }
                
            case .three:
                if actualValue.isEmpty {
                    currentFocusedField = .two
                } else {
                    currentFocusedField = .four
                    if case .update(let value) = nextUpdateAction {
                        nextUpdateAction = .none
                        code4 = value
                    }
                }
                
            case .four:
                if actualValue.isEmpty {
                    currentFocusedField = .three
                } else {
                    if codeLength == .four {
                        submitCode()
                    } else {
                        currentFocusedField = .five
                        if case .update(let value) = nextUpdateAction {
                            nextUpdateAction = .none
                            code5 = value
                        }
                    }
                }
                
            case .five:
                if actualValue.isEmpty {
                    currentFocusedField = .four
                } else {
                    currentFocusedField = .six
                    if case .update(let value) = nextUpdateAction {
                        nextUpdateAction = .none
                        code6 = value
                    }
                }
                
            case .six:
                if actualValue.isEmpty {
                    currentFocusedField = .five
                } else {
                    submitCode()
                }
            }
        }
        
        private func focusOnNextLeftField(field: OwnID.UISDK.OTPViewModel.FieldType) {
            switch field {
            case .one:
                break
            case .two:
                currentFocusedField = .one
            case .three:
                currentFocusedField = .two
            case .four:
                currentFocusedField = .three
            case .five:
                currentFocusedField = .four
            case .six:
                currentFocusedField = .five
            }
        }
    }
}

extension OwnID.UISDK {
    @available(iOS 15.0, *)
    public struct OTPTextFieldView: View {
        @ObservedObject var viewModel: OTPViewModel
        @FocusState private var focusedField: OwnID.UISDK.OTPViewModel.FieldType?
        private let boxSideSize: CGFloat = 50
        private let spaceBetweenBoxes: CGFloat = 8
        private let cornerRadius = 6.0
        
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
            .onChange(of: viewModel.currentFocusedField, perform: { newValue in
                focusedField = newValue
            })
            .onChange(of: viewModel.code1, perform: { newValue in
                viewModel.processTextChange(for: .one, binding: $viewModel.code1)
            })
            .onChange(of: viewModel.code2, perform: { newValue in
                viewModel.processTextChange(for: .two, binding: $viewModel.code2)
            })
            .onChange(of: viewModel.code3, perform: { newValue in
                viewModel.processTextChange(for: .three, binding: $viewModel.code3)
            })
            .onChange(of: viewModel.code4, perform: { newValue in
                viewModel.processTextChange(for: .four, binding: $viewModel.code4)
            })
            .onChange(of: viewModel.code5, perform: { newValue in
                viewModel.processTextChange(for: .five, binding: $viewModel.code5)
            })
            .onChange(of: viewModel.code6, perform: { newValue in
                viewModel.processTextChange(for: .six, binding: $viewModel.code6)
            })
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
