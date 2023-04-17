import XCTest
import Combine
@testable import OwnIDCoreSDK

final class EmptyContainer {
    
}

final class RegistrationPerformerMock: RegistrationPerformer {
    func register(configuration: OwnID.FlowsSDK.RegistrationConfiguration, parameters: RegisterParameters) -> OwnID.RegistrationResultPublisher {
        Just(OwnID.RegisterResult(operationResult: VoidOperationResult())).setFailureType(to: OwnID.CoreSDK.CoreErrorLogWrapper.self).eraseToAnyPublisher()
    }
}

final class LoginPerformerMock: LoginPerformer {
    func login(payload: OwnID.CoreSDK.Payload, email: String) -> OwnID.LoginResultPublisher {
        Just(OwnID.LoginResult(operationResult: VoidOperationResult())).setFailureType(to: OwnID.CoreSDK.CoreErrorLogWrapper.self).eraseToAnyPublisher()
    }
}

final class RegisterViewModelTests: XCTestCase {
    let sdkConfigurationName = OwnID.CoreSDK.sdkName
    var bag = Set<AnyCancellable>()
    
    override class func setUp() {
        super.setUp()
        OwnID.CoreSDK.shared.configureForTests()
    }
    
    func testErrorEmailMismatch() {
        let email1 = "111111@kfef.ee"
        let email2 = "222222@kfef.ee"
        let exp = expectation(description: #function)
        let eventPublisher = PassthroughSubject<Void, Never>()
        let emailPublisher = PassthroughSubject<String, Never>()
        let coreVMPublisher = PassthroughSubject<OwnID.CoreSDK.CoreViewModel.Event, OwnID.CoreSDK.CoreErrorLogWrapper>()
        let vm = OwnID.FlowsSDK.RegisterView.ViewModel(registrationPerformer: RegistrationPerformerMock(),
                                                       loginPerformer: LoginPerformerMock(),
                                                       sdkConfigurationName: sdkConfigurationName,
                                                       emailPublisher: emailPublisher.eraseToAnyPublisher())
        vm.eventPublisher.sink { result in
            switch result {
            case .success:
                XCTFail()
                
            case .failure(let error):
                switch error {
                case .plugin(underlying: let error):
                    if let error = error as? OwnID.FlowsSDK.RegisterError {
                        switch error {
                        case .emailMismatch:
                            exp.fulfill()
                        }
                    }
                    
                default:
                    break
                }
            }
        }
        .store(in: &bag)
        vm.subscribe(to: eventPublisher.eraseToAnyPublisher())
        vm.subscribe(to: coreVMPublisher.eraseToAnyPublisher(), persistingEmail: OwnID.CoreSDK.Email(rawValue: email1))
        emailPublisher.send(email1)
        eventPublisher.send(())
        sleep(1)
        emailPublisher.send(email2)
        vm.register()
        waitForExpectations(timeout: 0.1)
    }
    
    func testSuccessPath() {
        let email1 = "111111@kfef.ee"
        let exp = expectation(description: #function)
        let eventPublisher = PassthroughSubject<Void, Never>()
        let emailPublisher = PassthroughSubject<String, Never>()
        let coreVMPublisher = PassthroughSubject<OwnID.CoreSDK.CoreViewModel.Event, OwnID.CoreSDK.CoreErrorLogWrapper>()
        let vm = OwnID.FlowsSDK.RegisterView.ViewModel(registrationPerformer: RegistrationPerformerMock(),
                                                       loginPerformer: LoginPerformerMock(),
                                                       sdkConfigurationName: sdkConfigurationName,
                                                       emailPublisher: emailPublisher.eraseToAnyPublisher())
        vm.eventPublisher.sink { result in
            switch result {
            case .success(let event):
                switch event {
                case .loading:
                    break
                case .resetTapped:
                    break
                case .readyToRegister:
                    break
                case .userRegisteredAndLoggedIn:
                    exp.fulfill()
                }
                
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        .store(in: &bag)
        vm.subscribe(to: eventPublisher.eraseToAnyPublisher())
        vm.subscribe(to: coreVMPublisher.eraseToAnyPublisher(), persistingEmail: OwnID.CoreSDK.Email(rawValue: email1))
        emailPublisher.send(email1)
//        eventPublisher.send(())
        coreVMPublisher.send(.success(OwnID.CoreSDK.Payload(dataContainer: EmptyContainer(), metadata: EmptyContainer(), context: "", nonce: "", loginId: email1, responseType: .registrationInfo, authType: .none, requestLanguage: "")))
        sleep(1)
        vm.register()
        waitForExpectations(timeout: 0.1)
    }
}
