import XCTest
import Combine
@testable import OwnIDCoreSDK
@testable import OwnIDFlowsSDK

final class LoginPerformerPerformerMock: LoginPerformer {
    
    init(success: Bool = false) {
        self.success = success
    }
    
    func login(payload: OwnID.CoreSDK.Payload, email: String) -> AnyPublisher<OperationResult, OwnID.CoreSDK.Error> {
        publisher
    }
    
    func linkAndLogin(config: OwnID.FlowsSDK.LinkOnLoginConfiguration) -> AnyPublisher<OperationResult, OwnID.CoreSDK.Error> {
        publisher
    }
    
    var success = false
    
    private var publisher: AnyPublisher<OperationResult, OwnID.CoreSDK.Error> {
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

// Tests show that for fixed input there is fixed output
final class LoginViewModelTests: XCTestCase {
    //for each test case we have running new instance of XCTestCase, so we do not need to reset bag
    var bag = Set<AnyCancellable>()
    var viewModel: OwnID.FlowsSDK.LoginView.ViewModel!
    
    override class func setUp() {
        OwnID.CoreSDK.shared.configureForTests()
    }
    
    func testSetUp() {
        let performer = LoginPerformerPerformerMock(success: true)
        viewModel = OwnID.FlowsSDK.LoginView.ViewModel(loginPerformer: performer,
                                                       sdkConfigurationName: OwnID.CoreSDK.sdkName,
                                                       webLanguages: OwnID.CoreSDK.Languages.init(rawValue: []))
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
    
    func testCoreSDKFinishedSucessUserLoggedIn() {
        let performer = LoginPerformerPerformerMock(success: true)
        viewModel = OwnID.FlowsSDK.LoginView.ViewModel(loginPerformer: performer,
                                                       sdkConfigurationName: OwnID.CoreSDK.sdkName,
                                                       webLanguages: OwnID.CoreSDK.Languages.init(rawValue: []))
        viewModel.getEmail = { return "" }
        let expectation = self.expectation(description: #function)
        
        //Arrange (given)
        viewModel.eventPublisher
            .sink { event in
                switch event {
                case .success(let event):
                    if case .loggedIn = event {
                        //Assert (then)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    XCTFail("\(error)")
                }
            }
            .store(in: &bag)
        
        //Act (when)
        viewModel.subscribe(to: Result.success(.success(createPayload())).publisher.eraseToAnyPublisher())
        
        waitForExpectations(timeout: 2)
    }
    
    func testSucessFlow() {
        let performer = LoginPerformerPerformerMock(success: true)
        viewModel = OwnID.FlowsSDK.LoginView.ViewModel(loginPerformer: performer,
                                                       sdkConfigurationName: OwnID.CoreSDK.sdkName,
                                                       webLanguages: OwnID.CoreSDK.Languages.init(rawValue: []))
        viewModel.getEmail = { return "" }
        let expectation = self.expectation(description: #function)
        
        //Arrange (given)
        viewModel.eventPublisher
            .sink { event in
                switch event {
                case .success(let event):
                    if case .loggedIn = event {
                        //Assert (then)
                        expectation.fulfill()
                    }
                case .failure(let error):
                    XCTFail("\(error)")
                }
            }
            .store(in: &bag)
        
        //Act (when)
        viewModel.subscribe(to: Result.success(.success(createPayload())).publisher.eraseToAnyPublisher())
        
        waitForExpectations(timeout: 2)
    }
    
    func testErrorFromCoreSDK() {
        let performer = LoginPerformerPerformerMock(success: true)
        viewModel = OwnID.FlowsSDK.LoginView.ViewModel(loginPerformer: performer,
                                                       sdkConfigurationName: OwnID.CoreSDK.sdkName,
                                                       webLanguages: OwnID.CoreSDK.Languages.init(rawValue: []))
        let expectation = self.expectation(description: #function)
        
        //Arrange (given)
        viewModel.eventPublisher
            .sink { event in
                switch event {
                case .success:
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
        viewModel.subscribe(to: Result.failure(OwnID.CoreSDK.Error.flowCancelled).publisher.eraseToAnyPublisher())
        
        waitForExpectations(timeout: 2)
    }
}

private extension LoginViewModelTests {
    func createPayload() -> OwnID.CoreSDK.Payload {
        let payload = OwnID.CoreSDK.Payload(dataContainer: ["idToken": "dfkfnjng.z,kjdeiowq[ffgj"], metadata: .none, context: "dsdfw", nonce: "dskfjek", loginId: .none, responseType: .session)
        return payload
    }
}
