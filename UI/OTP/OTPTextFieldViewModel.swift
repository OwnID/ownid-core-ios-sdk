import SwiftUI
import Combine

@available(iOS 15.0, *)
extension OwnID.UISDK.OTPTextFieldView {
    final class ViewModel: ObservableObject {
        init(codeLength: OwnID.UISDK.OneTimePassword.CodeLength,
             store: Store<OwnID.UISDK.OneTimePassword.ViewState, OwnID.UISDK.OneTimePassword.Action>) {
            self.codeLength = codeLength
            self.store = store
            storage = Array(repeating: "", count: codeLength.rawValue + 1)
            
            store.send(.viewLoaded)
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
        private var disableTextFields = false
        
        @Published var currentFocusedField: FieldType?
        
        private var isResetting = false
        
        private func storeFieldValue(field: FieldType, value: String) {
            storage[field.rawValue] = value
        }
        
        func combineCode() -> String {
            let code = storage.reduce("", +)
            return code
        }
        
        private func submitCode() {
            disableTextFields = true
            let code = combineCode()
            if code.count == codeLength.rawValue {
                store.send(.codeEntered(code))
            }
        }
        
        private var lastFieldType: FieldType {
            switch codeLength {
            case .four:
                return .four
            case .six:
                return .six
            }
        }
        
        func processTextChange(for field: FieldType, binding: Binding<String>) {
            store.send(.codeEnteringStarted)
            
            let currentBindingValue = binding.wrappedValue
            let actualValue = currentBindingValue.replacingOccurrences(of: Self.zeroWidthSpaceCharacter, with: "")
            if actualValue.count > 1 {
                binding.wrappedValue = String(actualValue.prefix(1))
            }
            
            if !actualValue.isNumber {
                binding.wrappedValue = Self.zeroWidthSpaceCharacter
            }
            
            guard !isResetting else {
                if field == lastFieldType {
                    disableTextFields = false
                    isResetting = false
                    currentFocusedField = .one
                }
                return
            }
            
            guard !disableTextFields else {
                return
            }
            
            let nextActionIsAddZero = nextUpdateAction == .addEmptySpace
            if actualValue.isEmpty, !nextActionIsAddZero {
                binding.wrappedValue = Self.zeroWidthSpaceCharacter
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
            if actualValue.count == codeLength.rawValue {
                processPastedCode(actualValue)
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
            storeFieldValue(field: field, value: actualValue)
            moveFocusAndSubmitCodeIfNeeded(field, actualValue)
        }
        
        func resetCode() {
            isResetting = true
            code1 = Self.zeroWidthSpaceCharacter
            code2 = Self.zeroWidthSpaceCharacter
            code3 = Self.zeroWidthSpaceCharacter
            code4 = Self.zeroWidthSpaceCharacter
            if codeLength == .six {
                code5 = Self.zeroWidthSpaceCharacter
                code6 = Self.zeroWidthSpaceCharacter
            }
            storage = Array(repeating: "", count: codeLength.rawValue + 1)
        }
    }
}

@available(iOS 15.0, *)
private extension OwnID.UISDK.OTPTextFieldView.ViewModel {
    func moveFocusAndSubmitCodeIfNeeded(_ field: OwnID.UISDK.OTPTextFieldView.ViewModel.FieldType, _ actualValue: String) {
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
    
    func processPastedCode(_ actualValue: String) {
        nextUpdateAction = .updatingFromPasteboard
        let fieldValue = actualValue
        for index in 0...codeLength.rawValue - 1 {
            if let type = FieldType.typeForNumber(index + 1) {
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
                
                storeFieldValue(field: type, value: codeNumber)
            }
        }
        submitCode()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.nextUpdateAction = .none
        }
    }
    
    func focusOnNextLeftField(field: FieldType) {
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

@available(iOS 15.0, *)
extension OwnID.UISDK.OneTimePassword.CodeLength {
    var fields: [OwnID.UISDK.OTPTextFieldView.ViewModel.FieldType] {
        switch self {
        case .four:
            return [.one, .two, .three, .four]
            
        case .six:
            return [.one, .two, .three, .four, .five, .six]
        }
    }
}

@available(iOS 15.0, *)
extension OwnID.UISDK.OTPTextFieldView.ViewModel {
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

private extension String {
    var isNumber: Bool {
        let digitsCharacters = CharacterSet(charactersIn: "0123456789")
        return CharacterSet(charactersIn: self).isSubset(of: digitsCharacters)
    }
}
