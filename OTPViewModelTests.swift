import XCTest
import Combine
@testable import OwnIDCoreSDK

@available(iOS 15.0, *)
final class OTPViewModelTests: XCTestCase {
    func testCharacterSaveAndFocusMove() {
        let state = OwnID.UISDK.OneTimePassword.ViewState(isLoggingEnabled: false)
        let vm = OwnID.UISDK.OTPTextFieldView.ViewModel(
            codeLength: .six,
            store: .init(initialValue: state,
                         reducer: { OwnID.UISDK.OneTimePassword.viewModelReducer(state: &$0, action: $1) })
        )
        vm.processTextChange(for: .one, binding: .constant("1"))
        XCTAssertEqual(vm.combineCode(), "1")
        XCTAssertEqual(vm.currentFocusedField, .two)
        
        vm.processTextChange(for: .two, binding: .constant("2"))
        XCTAssertEqual(vm.combineCode(), "12")
        XCTAssertEqual(vm.currentFocusedField, .three)
        
        vm.processTextChange(for: .six, binding: .constant("123456"))
        XCTAssertEqual(vm.combineCode(), "123456")
        
        vm.processTextChange(for: .two, binding: .constant("123456"))
        XCTAssertEqual(vm.combineCode(), "123456")
    }
}
