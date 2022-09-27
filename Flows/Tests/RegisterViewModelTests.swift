
import XCTest
import Combine
@testable import OwnIDCoreSDK
@testable import OwnIDFlowsSDK

final class RegistrationPerformerMock: RegistrationPerformer {
    
    private let success: Bool
    
    init(success: Bool = true) {
        self.success = success
    }
    
    func register(configuration: OwnID.FlowsSDK.RegistrationConfiguration, parameters: RegisterParameters) -> AnyPublisher<OperationResult, OwnID.CoreSDK.Error> {
        if success {
            return Result.success(VoidOperationResult())
                .publisher
                .delay(for: 1, scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        } else {
            return Result.failure(OwnID.CoreSDK.Error.initRequestNetworkFailed(underlying: URLError(.badServerResponse)))
                .publisher
                .delay(for: 1, scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
    }
}

final class LoginPerformerMock: LoginPerformer {
    func login(payload: OwnIDCoreSDK.OwnID.CoreSDK.Payload, email: String) -> AnyPublisher<OwnIDFlowsSDK.OperationResult, OwnIDCoreSDK.OwnID.CoreSDK.Error> {
        if success {
            return Result.success(VoidOperationResult())
                .publisher
                .delay(for: 1, scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        } else {
            return Result.failure(OwnID.CoreSDK.Error.initRequestNetworkFailed(underlying: URLError(.badServerResponse)))
                .publisher
                .delay(for: 1, scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
    }
    
    
    private let success: Bool
    
    init(success: Bool = true) {
        self.success = success
    }
}

/// Tests show that for fixed input there is fixed output
final class RegisterViewViewModelTests: XCTestCase {
    //for each test case we have running new instance of XCTestCase, so we do not need to reset bag
    var bag = Set<AnyCancellable>()
    var viewModel: OwnID.FlowsSDK.RegisterView.ViewModel!
    let languages = OwnID.CoreSDK.Languages(rawValue: [])

    override class func setUp() {
        OwnID.CoreSDK.shared.configureForTests()
    }
    
    func testSetUp() {
        viewModel = OwnID.FlowsSDK.RegisterView.ViewModel(registrationPerformer: RegistrationPerformerMock(success: true),
                                                          loginPerformer: LoginPerformerPerformerMock(success: true),
                                                          sdkConfigurationName: OwnID.CoreSDK.sdkName,
                                                          webLanguages: languages)
        let expectation = self.expectation(description: #function)
        
        //Arrange (given)
        viewModel.$state
            .sink { event in
                //Assert (then)
                if case .initial = event {
                    expectation.fulfill()
                }
            }
            .store(in: &bag)
        
        //Act (when)
        //nothing here
        
        waitForExpectations(timeout: 1)
    }
    
    func testBaseSdkReturnErrorVMEmitsError() {
        viewModel = OwnID.FlowsSDK.RegisterView.ViewModel(registrationPerformer: RegistrationPerformerMock(success: false),
                                                          loginPerformer: LoginPerformerPerformerMock(success: true),
                                                          sdkConfigurationName: OwnID.CoreSDK.sdkName,
                                                          webLanguages: languages)
        let expectation = self.expectation(description: #function)
        
        //Arrange (given)
        viewModel.eventPublisher
            .sink { event in
                switch event {
                case .success(_):
                    break
                case .failure(let error):
                    if case .flowCancelled = error {
                        //Assert (then)
                        expectation.fulfill()
                    }
                }
            }
            .store(in: &bag)
        
        //Act (when)
        viewModel.subscribe(to: Result.failure(.flowCancelled).publisher.eraseToAnyPublisher(),
                            persistingEmail: OwnID.CoreSDK.Email(rawValue: "kejej@Jjrk.kjeje"))
        
        waitForExpectations(timeout: 1)
    }
    
    func testRegistrationReturnErrorVMEmitsError() {
        viewModel = OwnID.FlowsSDK.RegisterView.ViewModel(registrationPerformer: RegistrationPerformerMock(success: false),
                                                          loginPerformer: LoginPerformerPerformerMock(success: true),
                                                          sdkConfigurationName: OwnID.CoreSDK.sdkName,
                                                          webLanguages: languages)
        let email = "kejej@Jjrk.kjeje"
        viewModel.getEmail = { email }
        let expectation = self.expectation(description: #function)
        
        //Arrange (given)
        viewModel.eventPublisher
            .sink { event in
                switch event {
                case .success(_):
                    break
                case .failure(let error):
                    if case .initRequestNetworkFailed = error {
                        //Assert (then)
                        expectation.fulfill()
                    }
                }
            }
            .store(in: &bag)
        
        //Act (when)
        viewModel.subscribe(to: Result.success(.success(emptyPayload)).publisher.eraseToAnyPublisher(),
                            persistingEmail: OwnID.CoreSDK.Email(rawValue: email))
        viewModel.register(with: email)
        
        waitForExpectations(timeout: 1)
    }
    
    func testVMEmitsSuccess() {
        viewModel = OwnID.FlowsSDK.RegisterView.ViewModel(registrationPerformer: RegistrationPerformerMock(success: true),
                                                          loginPerformer: LoginPerformerPerformerMock(success: true),
                                                          sdkConfigurationName: OwnID.CoreSDK.sdkName,
                                                          webLanguages: languages)
        let expectation = self.expectation(description: #function)
        
        //Arrange (given)
        viewModel.eventPublisher
            .sink { event in
                switch event {
                case .success(let event):
                    if case .userRegisteredAndLoggedIn = event {
                        //Assert (then)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
            }
            .store(in: &bag)
        
        //Act (when)
        let email = "kejej@Jjrk.kjeje"
        viewModel.subscribe(to: Result.success(.success(emptyPayload)).publisher.eraseToAnyPublisher(),
                            persistingEmail: OwnID.CoreSDK.Email(rawValue: email))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewModel.register(with: email)
        }
        
        waitForExpectations(timeout: 2)
    }
    
    func testVMEmitsErrorDifferentEmails() {
        viewModel = OwnID.FlowsSDK.RegisterView.ViewModel(registrationPerformer: RegistrationPerformerMock(success: true),
                                                          loginPerformer: LoginPerformerPerformerMock(success: true),
                                                          sdkConfigurationName: OwnID.CoreSDK.sdkName,
                                                          webLanguages: languages)
        viewModel.getEmail = { "" }
        let expectation = self.expectation(description: #function)
        
        //Arrange (given)
        viewModel.eventPublisher
            .sink { event in
                switch event {
                case .success:
                    print("wdkwmdw")
                    
                case .failure(let event):
                    if case .plugin(let plugin) = event {
                        if case .enteredEmailMismatch = plugin as? OwnID.FlowsSDK.RegisterError {
                            //Assert (then)
                            expectation.fulfill()
                        }
                    }
                }
            }
            .store(in: &bag)
        
        //Act (when)
        viewModel.subscribe(to: Result.success(.success(emptyPayload)).publisher.eraseToAnyPublisher(), persistingEmail: OwnID.CoreSDK.Email(rawValue: "OTHER_EMAIL@Jjrk.kjeje"))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewModel.register(with: "kejej@Jjrk.kjeje")
        }
        
        waitForExpectations(timeout: 2)
    }
}

private extension RegisterViewViewModelTests {
    var emptyPayload: OwnID.CoreSDK.Payload {
        OwnID.CoreSDK.Payload(dataContainer: [String : Any](), metadata: .none, context: "", nonce: "", loginId: .none, responseType: .registrationInfo)
    }
}
