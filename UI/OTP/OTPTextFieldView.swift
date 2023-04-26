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
        
        let characterLimit = 1
        static let zeroWidthSpaceCharacter = "\u{200B}"
        
        @Published var code1 = zeroWidthSpaceCharacter
        @Published var code2 = zeroWidthSpaceCharacter
        @Published var code3 = zeroWidthSpaceCharacter
        @Published var code4 = zeroWidthSpaceCharacter
        @Published var code5 = zeroWidthSpaceCharacter
        @Published var code6 = zeroWidthSpaceCharacter
        @Published var nextUpdateAction: NextUpdateAcion?
        
        @Published var currentFocusedField: OwnID.UISDK.OTPViewModel.FieldType?
        
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
                processTextChange(for: .one, binding: $viewModel.code1)
            })
            .onChange(of: viewModel.code2, perform: { newValue in
                processTextChange(for: .two, binding: $viewModel.code2)
            })
            .onChange(of: viewModel.code3, perform: { newValue in
                processTextChange(for: .three, binding: $viewModel.code3)
            })
            .onChange(of: viewModel.code4, perform: { newValue in
                processTextChange(for: .four, binding: $viewModel.code4)
            })
            .onChange(of: viewModel.code5, perform: { newValue in
                processTextChange(for: .five, binding: $viewModel.code5)
            })
            .onChange(of: viewModel.code6, perform: { newValue in
                processTextChange(for: .six, binding: $viewModel.code6)
            })
            .onAppear() {
                focusedField = .one
            }
        }
        
        func processTextChange(for field: OwnID.UISDK.OTPViewModel.FieldType, binding: Binding<String>) {
            let currentBindingValue = binding.wrappedValue
            let actualValue = currentBindingValue.replacingOccurrences(of: OTPViewModel.zeroWidthSpaceCharacter, with: "")
            if !actualValue.isNumber {
                binding.wrappedValue = OTPViewModel.zeroWidthSpaceCharacter
            }
            let nextActionIsAddZero = viewModel.nextUpdateAction == OwnID.UISDK.OTPViewModel.NextUpdateAcion.addEmptySpace
            if actualValue.isEmpty, !nextActionIsAddZero {
                binding.wrappedValue = OTPViewModel.zeroWidthSpaceCharacter
                viewModel.nextUpdateAction = .addEmptySpace
                focusOnNextLeftField(field: field)
                return
            }
            if nextActionIsAddZero {
                viewModel.nextUpdateAction = .none
            }
            if case .updatingFromPasteboard = viewModel.nextUpdateAction {
                return
            }
            if actualValue.count == viewModel.codeLength.rawValue { // paste event of code
                viewModel.nextUpdateAction = .updatingFromPasteboard
                let fieldValue = actualValue
                for index in 0...viewModel.codeLength.rawValue - 1 {
                    if let type = OwnID.UISDK.OTPViewModel.FieldType.typeForNumber(index + 1) {
                        let character = fieldValue.prefix(index + 1).suffix(1)
                        let codeNumber = String(character)
                        switch type {
                        case .one:
                            viewModel.code1 = codeNumber
                        case .two:
                            viewModel.code2 = codeNumber
                        case .three:
                            viewModel.code3 = codeNumber
                        case .four:
                            viewModel.code4 = codeNumber
                        case .five:
                            viewModel.code5 = codeNumber
                        case .six:
                            viewModel.code6 = codeNumber
                        }
                        
                        viewModel.onUpdateOf(field: type, value: codeNumber)
                    }
                }
                viewModel.submitCode()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.nextUpdateAction = .none
                }
                return
            }
            var nextFieldValue = ""
            if actualValue.count > viewModel.characterLimit {
                let current = actualValue
                nextFieldValue = String(current.dropFirst(viewModel.characterLimit).prefix(viewModel.characterLimit))
                binding.wrappedValue = String(actualValue.prefix(viewModel.characterLimit))
                viewModel.nextUpdateAction = .update(nextFieldValue)
                return
            }
            viewModel.onUpdateOf(field: field, value: actualValue)
            switch field {
            case .one:
                if !actualValue.isEmpty {
                    focusedField = .two
                    if case .update(let value) = viewModel.nextUpdateAction {
                        viewModel.nextUpdateAction = .none
                        viewModel.code2 = value
                    }
                }
                
            case .two:
                if actualValue.isEmpty {
                    focusedField = .one
                } else {
                    focusedField = .three
                    if case .update(let value) = viewModel.nextUpdateAction {
                        viewModel.nextUpdateAction = .none
                        viewModel.code3 = value
                    }
                }
                
            case .three:
                if actualValue.isEmpty {
                    focusedField = .two
                } else {
                    focusedField = .four
                    if case .update(let value) = viewModel.nextUpdateAction {
                        viewModel.nextUpdateAction = .none
                        viewModel.code4 = value
                    }
                }
                
            case .four:
                if actualValue.isEmpty {
                    focusedField = .three
                } else {
                    if viewModel.codeLength == .four {
                        viewModel.submitCode()
                    } else {
                        focusedField = .five
                        if case .update(let value) = viewModel.nextUpdateAction {
                            viewModel.nextUpdateAction = .none
                            viewModel.code5 = value
                        }
                    }
                }
                
            case .five:
                if actualValue.isEmpty {
                    focusedField = .four
                } else {
                    focusedField = .six
                    if case .update(let value) = viewModel.nextUpdateAction {
                        viewModel.nextUpdateAction = .none
                        viewModel.code6 = value
                    }
                }
                
            case .six:
                if actualValue.isEmpty {
                    focusedField = .five
                } else {
                    viewModel.submitCode()
                }
            }
        }
        
        func focusOnNextLeftField(field: OwnID.UISDK.OTPViewModel.FieldType) {
            switch field {
            case .one:
                break
            case .two:
                focusedField = .one
            case .three:
                focusedField = .two
            case .four:
                focusedField = .three
            case .five:
                focusedField = .four
            case .six:
                focusedField = .five
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
