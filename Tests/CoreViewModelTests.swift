import XCTest
import Combine
@testable import OwnIDCoreSDK

extension OwnID.CoreSDK.AccountManager {
    static var mockAccountManager: CreationClosure {
        { store, domain, challenge, browserBaseURL in
            let credentialID = "jdfhdj323"
            let clientDataJSON = "{\"key\":\"value\"}".data(using: .utf8)!
            let rawAuthenticatorData = "rawAuthenticatorData"
            let signature = "signature"
            let attestationObject = "attestationObject"
            let current = Self {
                let payload = OwnID.CoreSDK.Fido2LoginPayload(credentialId: credentialID,
                                                              clientDataJSON: clientDataJSON.base64urlEncodedString(),
                                                              authenticatorData: rawAuthenticatorData,
                                                              signature: signature)
                store.send(.didFinishLogin(fido2LoginPayload: payload, browserBaseURL: browserBaseURL))
            } cancelClosure: {
                
            } signUpClosure: { userName in
                let payload = OwnID.CoreSDK.Fido2RegisterPayload(credentialId: credentialID,
                                                                 clientDataJSON: clientDataJSON.base64urlEncodedString(),
                                                                 attestationObject: attestationObject)
                store.send(.didFinishRegistration(fido2RegisterPayload: payload, browserBaseURL: browserBaseURL))
            }
            return current
        }
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
    
    static var successSession: APISessionProtocol.CreationClosure {
        { _, _ , _ , _ ,_  in OwnID.CoreSDK.APISessionMockSuccess() }
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
        let exp = expectation(description: #function)
        var config = try! OwnID.CoreSDK.LocalConfiguration(appID: "e8qkk8umn5hxqg", redirectionURL: "com.ownid.demo.firebase://ownid/redirect/", environment: "staging")
        let domain = "https://ownid.com"
        config.serverURL = URL(string: domain)!
        let settings = OwnID.CoreSDK.FidoSettings(rpID: domain, rpName: domain)
        config.fidoSettings = settings
        let viewModel = OwnID.CoreSDK.CoreViewModel(type: .register,
                                                    email: .init(rawValue: "lesot21279@duiter.com"),
                                                    supportedLanguages: .init(rawValue: ["en"]),
                                                    sdkConfigurationName: sdkConfigurationName,
                                                    isLoggingEnabled: true,
                                                    clientConfiguration: config,
                                                    apiSessionCreationClosure: OwnID.CoreSDK.successSession,
                                                    createAccountManagerClosure: OwnID.CoreSDK.AccountManager.mockAccountManager)
        
        viewModel.eventPublisher.sink { completion in
            switch completion {
            case .finished:
                break
                
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        } receiveValue: { event in
            switch event {
            case .loading:
                break
            case .success(_):
                exp.fulfill()
            case .cancelled:
                XCTFail()
            }
        }
        .store(in: &bag)
        
        
        viewModel.start()
        waitForExpectations(timeout: 0.1)
    }
}
