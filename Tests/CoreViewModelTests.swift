import XCTest
import Combine
@testable import OwnIDCoreSDK

extension CoreViewModelTests {
    static var successSession: OwnID.CoreSDK.CoreViewModel.ApiSessionCreationClosure {
        { _, _ , _ , _ ,_  in OwnID.CoreSDK.APISessionMockSuccess() }
    }
}

extension OwnID.CoreSDK {
    final class APISessionMockSuccess: APISessionProtocol {
        var context: OwnID.CoreSDK.Context! { "KreJ96smzSwveEb5QfaJzJ" }
        var nonce: OwnID.CoreSDK.Nonce { "acfc66ed-8c1a-4956-b114-e9fa0e189cd7" }
        
        func performInitRequest(requestData: OwnID.CoreSDK.Init.RequestData) -> AnyPublisher<OwnID.CoreSDK.Init.Response, OwnID.CoreSDK.CoreErrorLogWrapper> {
            Just(OwnID.CoreSDK.Init.Response(url: "https://www.apple.com", context: context, nonce: nonce)).setFailureType(to: OwnID.CoreSDK.CoreErrorLogWrapper.self).eraseToAnyPublisher()
        }
        
        func performFinalStatusRequest() -> AnyPublisher<OwnID.CoreSDK.Payload, OwnID.CoreSDK.CoreErrorLogWrapper> {
            Just(OwnID.CoreSDK.Payload(dataContainer: .none, metadata: .none, context: context, nonce: nonce, loginId: .none, responseType: .registrationInfo, authType: .none, requestLanguage: .none)).setFailureType(to: OwnID.CoreSDK.CoreErrorLogWrapper.self).eraseToAnyPublisher()
        }
        
        func performAuthRequest(fido2Payload: Encodable) -> AnyPublisher<OwnID.CoreSDK.Payload, OwnID.CoreSDK.CoreErrorLogWrapper> {
            Just(OwnID.CoreSDK.Payload(dataContainer: [:], metadata: .none, context: context, nonce: nonce, loginId: .none, responseType: .registrationInfo, authType: "biometrics", requestLanguage: "uk-US")).setFailureType(to: OwnID.CoreSDK.CoreErrorLogWrapper.self).eraseToAnyPublisher()
        }
    }
}

final class CoreViewModelTests: XCTestCase {
    let sdkConfigurationName = OwnID.CoreSDK.sdkName
    var bag = Set<AnyCancellable>()
    
    override class func setUp() {
        super.setUp()
        OwnID.CoreSDK.shared.configureForTests()
    }
    
    func testErrorEmptyEmail() {
        let exp = expectation(description: #function)
        
        let model = OwnID.CoreSDK.shared.createCoreViewModelForRegister(sdkConfigurationName: sdkConfigurationName)
        model.eventPublisher.sink { completion in
            switch completion {
            case .finished:
                break
                
            case .failure(let error):
                if case .emailIsInvalid = error.error {
                    exp.fulfill()
                } else {
                    XCTFail()
                }
            }
        } receiveValue: { _ in }
            .store(in: &bag)
        
        model.start()
        waitForExpectations(timeout: 0.01)
    }
    
    func testSuccessRegistrationPathWithPasskeys() {
        let viewModel = OwnID.CoreSDK.CoreViewModel(type: .register,
                                                    email: .none,
                                      supportedLanguages: .init(rawValue: ["en"]),
                                      sdkConfigurationName: sdkConfigurationName,
                                      isLoggingEnabled: true,
                                                    clientConfiguration: try! OwnID.CoreSDK.LocalConfiguration(appID: "e8qkk8umn5hxqg", redirectionURL: "com.ownid.demo.firebase://ownid/redirect/", environment: "staging"), apiSessionCreationClosure: Self.successSession)
//        viewModel.subscribeToURL(publisher: urlPublisher.eraseToAnyPublisher())
//        viewModel.subscribeToConfiguration(publisher: configurationLoadingEventPublisher.eraseToAnyPublisher())
    }
}
