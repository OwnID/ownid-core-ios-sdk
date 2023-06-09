import XCTest
import Combine
@testable import OwnIDCoreSDK

extension OwnID.CoreSDK.BrowserOpener {
    static var instantOpener: CreationClosure {
        { store, url, redirectionURL in
            let schemeURL = URL(string: redirectionURL)!
            let configName = store.value
            OwnID.CoreSDK.shared.handle(url: schemeURL, sdkConfigurationName: configName)
            return Self { }
        }
    }
}

extension OwnID.CoreSDK.AccountManager {
    static var mockAccountManager: CreationClosure {
        { store, domain, challenge, browserBaseURL in
            let credentialID = "jdfhdj323"
            let clientDataJSON = "{\"key\":\"value\"}".data(using: .utf8)!
            let rawAuthenticatorData = "rawAuthenticatorData"
            let signature = "signature"
            let attestationObject = "attestationObject"
            let current = Self { credId in
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
    
    static var mockErrorAccountManager: CreationClosure {
        { store, domain, challenge, browserBaseURL in
            let current = Self { credId in
                store.send(.error(error: .authorizationManagerAuthError(underlying: OwnID.CoreSDK.Error.dataIsMissing), context: "frogkolvjt", browserBaseURL: browserBaseURL))
            } cancelClosure: {
                
            } signUpClosure: { userName in
                store.send(.error(error: .authorizationManagerAuthError(underlying: OwnID.CoreSDK.Error.dataIsMissing), context: "frogkolvjt", browserBaseURL: browserBaseURL))
            }
            return current
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
        
        let model = OwnID.CoreSDK.shared.createCoreViewModelForRegister(loginId: "", sdkConfigurationName: sdkConfigurationName)
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
        let viewModel = OwnID.CoreSDK.CoreViewModel(type: .register,
                                                    loginId: "lesot21279@duiter.com",
                                                    supportedLanguages: .init(rawValue: ["en"]),
                                                    sdkConfigurationName: sdkConfigurationName,
                                                    isLoggingEnabled: true,
                                                    clientConfiguration: localConfig,
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
    
    func testAuthManagerError() {
        let exp = expectation(description: #function)
        let viewModel = OwnID.CoreSDK.CoreViewModel(type: .register,
                                                    loginId: "lesot21279@duiter.com",
                                                    supportedLanguages: .init(rawValue: ["en"]),
                                                    sdkConfigurationName: sdkConfigurationName,
                                                    isLoggingEnabled: true,
                                                    clientConfiguration: localConfig,
                                                    createAccountManagerClosure: OwnID.CoreSDK.AccountManager.mockErrorAccountManager,
                                                    createBrowserOpenerClosure: OwnID.CoreSDK.BrowserOpener.instantOpener)
        
        viewModel.eventPublisher.sink { completion in
            switch completion {
            case .finished:
                break
                
            case .failure(let error):
                switch error.error {
                case .authorizationManagerAuthError(_):
                    // intentionally need to fail, as we open browser after autohization fails, we should not see this error at all
                    XCTFail()
                default:
                    break
                }
            }
        } receiveValue: { event in
            switch event {
            case .loading:
                viewModel.subscribeToURL(publisher: Just(()).setFailureType(to: OwnID.CoreSDK.CoreErrorLogWrapper.self).eraseToAnyPublisher())
                
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
    
    var localConfig: OwnID.CoreSDK.LocalConfiguration {
        var config = try! OwnID.CoreSDK.LocalConfiguration(appID: "e8qkk8umn5hxqg", redirectionURL: "com.ownid.demo.firebase://ownid/redirect/", environment: "staging")
        let domain = "https://ownid.com"
        config.serverURL = URL(string: domain)!
        return config
    }
    
    func testInitResponseError() {
        let exp = expectation(description: #function)
        let viewModel = OwnID.CoreSDK.CoreViewModel(type: .register,
                                                    loginId: "lesot21279@duiter.com",
                                                    supportedLanguages: .init(rawValue: ["en"]),
                                                    sdkConfigurationName: sdkConfigurationName,
                                                    isLoggingEnabled: true,
                                                    clientConfiguration: localConfig,
                                                    createAccountManagerClosure: OwnID.CoreSDK.AccountManager.mockErrorAccountManager, createBrowserOpenerClosure: OwnID.CoreSDK.BrowserOpener.instantOpener)
        
        viewModel.eventPublisher.sink { completion in
            switch completion {
            case .finished:
                break
                
            case .failure(let error):
                switch error.error {
                case .requestResponseIsEmpty:
                    exp.fulfill()
                default:
                    break
                }
            }
        } receiveValue: { _ in }
        .store(in: &bag)
        
        viewModel.start()
        waitForExpectations(timeout: 0.1)
    }
}
