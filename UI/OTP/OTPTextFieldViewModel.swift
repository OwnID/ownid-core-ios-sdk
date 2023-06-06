import SwiftUI
import Combine

@available(iOS 15.0, *)
extension OwnID.UISDK.OTPTextFieldView {
    final class ViewModel: ObservableObject {
        private struct Constants {
            static let characterLimit = 1
            static let zeroWidthSpaceCharacter = "\u{200B}"
        }
        
        init(codeLength: Int,
             store: Store<OwnID.UISDK.OneTimePassword.ViewState, OwnID.UISDK.OneTimePassword.Action>) {
            self.codeLength = codeLength
            self.store = store
            storage = Array(repeating: "", count: codeLength + 1)
            codes = Array(repeating: Constants.zeroWidthSpaceCharacter, count: codeLength)
            
            store.send(.viewLoaded)
        }
        
        let codeLength: Int
        
        private let store: Store<OwnID.UISDK.OneTimePassword.ViewState, OwnID.UISDK.OneTimePassword.Action>
        private var storage: [String]
        
        @Published var codes: [String]
        @Published var nextUpdateAction: NextUpdateAcion?
        private var disableTextFields = false
        
        @Published var currentFocusedFieldIndex: Int?
        
        private var isResetting = false
        
        private func storeFieldValue(index: Int, value: String) {
            storage[index] = value
        }
        
        func combineCode() -> String {
            let code = storage.reduce("", +)
            return code
        }
        
        private func submitCode() {
            disableTextFields = true
            let code = combineCode()
            if code.count == codeLength {
                store.send(.codeEntered(code))
            }
        }
        
        func processTextChange(for index: Int, binding: Binding<String>) {
            store.send(.codeEnteringStarted)
            
            let currentBindingValue = binding.wrappedValue
            let actualValue = currentBindingValue.replacingOccurrences(of: Constants.zeroWidthSpaceCharacter, with: "")
            if actualValue.count > Constants.characterLimit {
                binding.wrappedValue = String(actualValue.prefix(Constants.characterLimit))
            }
            
            if !actualValue.isNumber {
                binding.wrappedValue = Constants.zeroWidthSpaceCharacter
            }
            
            guard !isResetting else {
                if index == codeLength - 1 {
                    disableTextFields = false
                    isResetting = false
                    currentFocusedFieldIndex = 0
                }
                return
            }
            
            guard !disableTextFields else {
                return
            }
            
            let nextActionIsAddZero = nextUpdateAction == .addEmptySpace
            if actualValue.isEmpty, !nextActionIsAddZero {
                binding.wrappedValue = Constants.zeroWidthSpaceCharacter
                nextUpdateAction = .addEmptySpace
                focusOnNextLeftField(fieldIndex: index)
                return
            }
            if nextActionIsAddZero {
                nextUpdateAction = .none
            }
            if case .updatingFromPasteboard = nextUpdateAction {
                return
            }
            if actualValue.count == codeLength {
                processPastedCode(actualValue)
                return
            }
            
            var nextFieldValue = ""
            if actualValue.count > Constants.characterLimit {
                let current = actualValue
                nextFieldValue = String(current.dropFirst(Constants.characterLimit).prefix(Constants.characterLimit))
                binding.wrappedValue = String(actualValue.prefix(Constants.characterLimit))
                nextUpdateAction = .update(nextFieldValue)
                return
            }
            storeFieldValue(index: index, value: actualValue)
            moveFocusAndSubmitCodeIfNeeded(index, actualValue)
        }
        
        func resetCode() {
            isResetting = true
            for i in 0..<codes.count {
                codes[i] = Constants.zeroWidthSpaceCharacter
            }
            storage = Array(repeating: "", count: codeLength + 1)
        }
    }
}

@available(iOS 15.0, *)
private extension OwnID.UISDK.OTPTextFieldView.ViewModel {
    func moveFocusAndSubmitCodeIfNeeded(_ index: Int, _ actualValue: String) {
        if actualValue.isEmpty {
            focusOnNextLeftField(fieldIndex: index)
        } else {
            if index == codeLength - 1 {
                submitCode()
            } else {
                currentFocusedFieldIndex = index + 1
                if case .update(let value) = nextUpdateAction {
                    nextUpdateAction = .none
                    codes[index] = value
                }
            }
        }
    }
    
    func processPastedCode(_ actualValue: String) {
        nextUpdateAction = .updatingFromPasteboard
        let fieldValue = actualValue
        for index in 0...codeLength - 1 {
            let character = fieldValue.prefix(index + 1).suffix(1)
            let codeNumber = String(character)
            codes[index] = codeNumber
            storeFieldValue(index: index, value: codeNumber)
        }
        submitCode()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.nextUpdateAction = .none
        }
    }
    
    func focusOnNextLeftField(fieldIndex: Int) {
        guard fieldIndex > 0 else { return }
        currentFocusedFieldIndex = fieldIndex - 1
    }
}

@available(iOS 15.0, *)
extension OwnID.UISDK.OTPTextFieldView.ViewModel {
    enum NextUpdateAcion: Equatable {
        case update(String)
        case updatingFromPasteboard
        case addEmptySpace
    }
}

private extension String {
    var isNumber: Bool {
        let digitsCharacters = CharacterSet(charactersIn: "0123456789")
        return CharacterSet(charactersIn: self).isSubset(of: digitsCharacters)
    }
}
