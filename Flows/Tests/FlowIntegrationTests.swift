import XCTest
import Combine
import MockSDK
@testable import OwnIDCoreSDK
@testable import OwnIDFlowsSDK

/// Tests show that for fixed input there is fixed output
final class FlowIntegrationTests: XCTestCase {
    //for each test case we have running new instance of XCTestCase, so we do not need to reset bag
    var bag = Set<AnyCancellable>()
    var viewModel: OwnID.FlowsSDK.RegisterView.ViewModel!
    var coreVM: OwnID.CoreSDK.CoreViewModel!
    
    override class func setUp() {
        OwnID.CoreSDK.shared.configureForTests()
    }
    
    var session: OwnID.CoreSDK.APISession {
        let serverURL = OwnID.CoreSDK.shared.serverURL(for: OwnID.CoreSDK.sdkName)
        let statusURL = OwnID.CoreSDK.shared.statusURL(for: OwnID.CoreSDK.sdkName)
        let session = OwnID.CoreSDK.APISession(serverURL: serverURL,
                                               statusURL: statusURL,
                                               webLanguages: languages)
        return session
    }
    
    let languages = OwnID.CoreSDK.Languages.init(rawValue: [])
    
    func testRegistrationEmitsErrorOnCoreError() {
        //Arrange (given)
        let emailTest = "yjehj@nkk.lkjje"
        let coreVM = OwnID.CoreSDK.CoreViewModel(type: .register,
                                                   email: OwnID.CoreSDK.Email(rawValue: emailTest),
                                                   token: .none,
                                                   session: session,
                                                   sdkConfigurationName: OwnID.CoreSDK.sdkName)
        
        let viewModel = OwnID.FlowsSDK.RegisterView.ViewModel(registrationPerformer: RegistrationPerformerMock(success: false),
                                                              sdkConfigurationName: OwnID.CoreSDK.sdkName, webLanguages: languages)
        viewModel.subscribe(to: coreVM.eventPublisher, persistingEmail: OwnID.CoreSDK.Email(rawValue: emailTest))
        
        let expectation = self.expectation(description: #function)
        
        viewModel.eventPublisher
            .sink { event in
                switch event {
                case .success(_):
                    break
                case .failure(let error):
                    if case .initRequestResponseDecodeFailed = error {
                        //Assert (then)
                        expectation.fulfill()
                    }
                }
            }
            .store(in: &bag)
        
        //Act (when)
        coreVM.start()
        
        waitForExpectations(timeout: 1)
    }
    
    func testRegistrationSuccess() {
        //Arrange (given)
        let emailTest = "yjehj@nkk.lkjje"
        coreVM = OwnID.CoreSDK.CoreViewModel(type: .register,
                                                   email: OwnID.CoreSDK.Email(rawValue: emailTest),
                                                   token: .none,
                                                   session: APISessionStub(isInitSuccess: true, isStatusSuccess: true),
                                                   sdkConfigurationName: OwnID.CoreSDK.sdkName)

        viewModel = OwnID.FlowsSDK.RegisterView.ViewModel(registrationPerformer: RegistrationPerformerMock(success: true),
                                                          sdkConfigurationName: OwnID.CoreSDK.sdkName,
                                                          webLanguages: languages)
        viewModel.subscribe(to: coreVM.eventPublisher, persistingEmail: OwnID.CoreSDK.Email(rawValue: emailTest))

        let expectation = self.expectation(description: #function)

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
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            self.coreVM.store.send(.statusRequestLoaded(response: self.emptyPayload))

            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                self.viewModel.register(with: emailTest)
            }
        }

        waitForExpectations(timeout: 4 + 2 + 3)
    }
    
    var emptyPayload: OwnID.CoreSDK.Payload {
        OwnID.CoreSDK.Payload(dataContainer: [String : Any](), metadata: .none, context: "", nonce: "", loginId: .none, responseType: .session)
    }

    func testLoginEmitsErrorOnCoreError() {
        //Arrange (given)
        let coreVM = OwnID.CoreSDK.CoreViewModel(type: .register,
                                                 email: OwnID.CoreSDK.Email(rawValue: "yjehj@nkk.lkjje"),
                                                 token: .none,
                                                 session: APISessionStub(isInitSuccess: false, isStatusSuccess: true),
                                                 sdkConfigurationName: OwnID.CoreSDK.sdkName)
        let viewModel = OwnID.FlowsSDK.LoginView.ViewModel(loginPerformer: LoginPerformerPerformerMock(success: false),
                                                           sdkConfigurationName: OwnID.CoreSDK.sdkName,
                                                           webLanguages: languages)
        viewModel.subscribe(to: coreVM.eventPublisher)
        
        let expectation = self.expectation(description: #function)
        
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
        coreVM.start()
        
        waitForExpectations(timeout: 2)
    }

    func testLoginSuccess() {
        //Arrange (given)
        let email = "yjehj@nkk.lkjje"
        coreVM = OwnID.CoreSDK.CoreViewModel(type: .logIn,
                                             email: OwnID.CoreSDK.Email(rawValue: email),
                                             token: .none,
                                             session: APISessionStub(isInitSuccess: true, isStatusSuccess: true),
                                             sdkConfigurationName: OwnID.CoreSDK.sdkName)
        let viewModel = OwnID.FlowsSDK.LoginView.ViewModel(loginPerformer: LoginPerformerPerformerMock(success: true), sdkConfigurationName: OwnID.CoreSDK.sdkName, webLanguages: languages)
        viewModel.subscribe(to: coreVM.eventPublisher)
        viewModel.getEmail = { return email }
        
        let expectation = self.expectation(description: #function)

        viewModel.eventPublisher
            .sink { event in
                switch event {
                case .success(let event):
                    if case .loggedIn = event {
                        //Assert (then)
                        expectation.fulfill()
                    }

                case .failure:
                    break
                }
            }
            .store(in: &bag)

        //Act (when)
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            self.coreVM.store.send(.statusRequestLoaded(response: self.emptyPayload))
        }

        waitForExpectations(timeout: 10)
    }
}
