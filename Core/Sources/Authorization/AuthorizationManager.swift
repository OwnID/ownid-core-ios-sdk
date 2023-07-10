import AuthenticationServices
import os

extension OwnID.CoreSDK.AccountManager {
    typealias CreationClosure = (_ store: Store<State, Action>, _ domain: String, _ challenge: String, _ browserBaseURL: String) -> Self
    static var defaultAccountManager: CreationClosure {
        { store, domain, challenge, browserBaseURL in
            let manager = OwnID.CoreSDK.CurrentAccountManager(store: store, domain: domain, challenge: challenge, browserBaseURL: browserBaseURL)
            let current = Self { credId in
                if #available(iOS 16.0, *) {
                    manager.signIn(credId: credId)
                }
            } cancelClosure: {
                if #available(iOS 16.0, *) {
                    manager.cancel()
                }
            } signUpClosure: { userName in
                if #available(iOS 16.0, *) {
                    manager.signUpWith(userName: userName)
                }
            }
            return current
        }
    }
}

extension OwnID.CoreSDK {
    struct AccountManager {
        var signInClosure: (_ credId: String) -> Void
        var cancelClosure: () -> Void
        var signUpClosure: (_ userName: String) -> Void
        
        func signIn(credId: String) {
            signInClosure(credId)
        }
        
        func cancel() {
            cancelClosure()
        }
        
        func signUpWith(userName: String) {
            signUpClosure(userName)
        }
    }
}

extension OwnID.CoreSDK.AccountManager {
    struct State: LoggingEnabled {
        let isLoggingEnabled: Bool
    }
    
    enum Action {
        case didFinishRegistration(fido2RegisterPayload: OwnID.CoreSDK.Fido2RegisterPayload, browserBaseURL: String)
        case didFinishLogin(fido2LoginPayload: OwnID.CoreSDK.Fido2LoginPayload, browserBaseURL: String)
        case error(error: AuthManagerError, context: OwnID.CoreSDK.Context, browserBaseURL: String)
    }
    
    enum AuthManagerError: Error {
        case authorizationManagerGeneralError(underlying: Swift.Error)
        case authorizationManagerCredintialsNotFoundOrCanlelledByUser(underlying: ASAuthorizationError)
        case authorizationManagerAuthError(underlying: Swift.Error)
        case authorizationManagerDataMissing
        case authorizationManagerUnknownAuthType
        
        public var errorDescription: String {
            return "Error while performing action"
        }
    }
}

@available(iOS 16.0, *)
extension OwnID.CoreSDK.CurrentAccountManager: ASAuthorizationControllerDelegate { }
    
extension OwnID.CoreSDK {
    #warning("now can be moved to UI layer if needed https://developer.apple.com/documentation/authenticationservices/authorizationcontroller")
    final class CurrentAccountManager: NSObject {
        let authenticationAnchor = ASPresentationAnchor()
        
        private let store: Store<OwnID.CoreSDK.AccountManager.State, OwnID.CoreSDK.AccountManager.Action>
        private let domain: String
        private let challenge: String
        private let browserBaseURL: String
        
        private var challengeData: Data {
            challenge.data(using: .utf8)!
        }
        
        private var currentAuthController: ASAuthorizationController?
        private var isPerformingModalReqest = false
        
        init(store: Store<OwnID.CoreSDK.AccountManager.State, OwnID.CoreSDK.AccountManager.Action>, domain: String, challenge: String, browserBaseURL: String) {
            self.store = store
            self.domain = domain
            self.challenge = challenge
            self.browserBaseURL = browserBaseURL
        }
        
        @available(iOS 16.0, *)
        func cancel() {
            currentAuthController?.cancel()
        }
        
        @available(iOS 16.0, *)
        func signIn(credId: String) {
            currentAuthController?.cancel()
            let securityKeyProvider = ASAuthorizationSecurityKeyPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
            let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
            
            let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challengeData)
            let securityKeyRequest = securityKeyProvider.createCredentialAssertionRequest(challenge: challengeData)
            if let data = Data(base64urlEncoded: credId) {
                let cred = ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: data)
                assertionRequest.allowedCredentials = [cred]
            }
            let requests = [assertionRequest, securityKeyRequest]
            let authController = ASAuthorizationController(authorizationRequests: requests)
            authController.delegate = self
            authController.presentationContextProvider = self
            
            currentAuthController = authController
            // If credentials are available, presents a modal sign-in sheet.
            // If there are no locally saved credentials, the system presents a QR code to allow signing in with a
            // passkey from a nearby device.
            authController.performRequests()
            
            isPerformingModalReqest = true
        }
        
        @available(iOS 16.0, *)
        func beginAutoFillAssistedPasskeySignIn() {
            if true {
                print("For now autofill is not supported right here, we need some other way to enable this as we need new challenge for this")
                return
            }
            currentAuthController?.cancel()
            
            let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
            let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challengeData)
            
            let authController = ASAuthorizationController(authorizationRequests: [assertionRequest])
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performAutoFillAssistedRequests()
            currentAuthController = authController
        }
        
        @available(iOS 16.0, *)
        func signUpWith(userName: String) {
            currentAuthController?.cancel()
            let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
            
            /// `createCredentialRegistrationRequest` also creates new credential if provided the same
            /// Registering a passkey with the same user ID as an existing one overwrites the existing passkey on the user’s devices.
            let registrationRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(challenge: challengeData,
                                                                                                      name: userName,
                                                                                                      userID: userName.data(using: .utf8)!)
            
            let authController = ASAuthorizationController(authorizationRequests: [registrationRequest])
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performRequests()
            currentAuthController = authController
            isPerformingModalReqest = true
        }
        
        @available(iOS 16.0, *)
        func authorizationController(controller: ASAuthorizationController,
                                     didCompleteWithAuthorization authorization: ASAuthorization) {
            switch authorization.credential {
            case let credentialRegistration as ASAuthorizationPlatformPublicKeyCredentialRegistration:
                // Verify the attestationObject and clientDataJSON with your service.
                // The attestationObject contains the user's new public key to store and use for subsequent sign-ins.
                guard let attestationObject = credentialRegistration.rawAttestationObject?.base64urlEncodedString()
                else {
                    store.send(.error(error: .authorizationManagerDataMissing, context: challenge, browserBaseURL: browserBaseURL))
                    return
                }
                
                let clientDataJSON = credentialRegistration.rawClientDataJSON.base64urlEncodedString()
                let credentialID = credentialRegistration.credentialID.base64urlEncodedString()
                
                // After the server verifies the registration and creates the user account, sign in the user with the new account.
                
                let payload = OwnID.CoreSDK.Fido2RegisterPayload(credentialId: credentialID,
                                                                 clientDataJSON: clientDataJSON,
                                                                 attestationObject: attestationObject)
                store.send(.didFinishRegistration(fido2RegisterPayload: payload, browserBaseURL: browserBaseURL))
                
            case let credentialAssertion as ASAuthorizationPlatformPublicKeyCredentialAssertion:
                // Verify the below signature and clientDataJSON with your service for the given userID.
                let signature = credentialAssertion.signature.base64urlEncodedString()
                let rawAuthenticatorData = credentialAssertion.rawAuthenticatorData.base64urlEncodedString()
                let clientDataJSON = credentialAssertion.rawClientDataJSON
                let credentialID = credentialAssertion.credentialID.base64urlEncodedString()
                
                let payload = OwnID.CoreSDK.Fido2LoginPayload(credentialId: credentialID,
                                                              clientDataJSON: clientDataJSON.base64urlEncodedString(),
                                                              authenticatorData: rawAuthenticatorData,
                                                              signature: signature)
                store.send(.didFinishLogin(fido2LoginPayload: payload, browserBaseURL: browserBaseURL))
                
            default:
                store.send(.error(error: .authorizationManagerUnknownAuthType, context: challenge, browserBaseURL: browserBaseURL))
            }
            
            isPerformingModalReqest = false
        }
        
        deinit {
            if #available(iOS 16.0, *) {
                currentAuthController?.cancel()
            }
        }
        
        @available(iOS 16.0, *)
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Swift.Error) {
            defer {
                OwnID.CoreSDK.logger.log(.entry(level: .warning,
                                                message: "Fido error \(error.localizedDescription)",
                                                exception: (error as NSError).domain,
                                                Self.self))
                currentAuthController?.cancel()
                controller.cancel()
            }
            guard let authorizationError = error as? ASAuthorizationError else {
                isPerformingModalReqest = false
                store.send(.error(error: .authorizationManagerGeneralError(underlying: error), context: challenge, browserBaseURL: browserBaseURL))
                return
            }
            
            if authorizationError.code == .canceled {
                // Either the system doesn't find any credentials and the request ends silently, or the user cancels the request.
                // This is a good time to show a traditional login form, or ask the user to create an account.
                
                if isPerformingModalReqest {
                    store.send(.error(error: .authorizationManagerCredintialsNotFoundOrCanlelledByUser(underlying: authorizationError), context: challenge, browserBaseURL: browserBaseURL))
                }
            } else {
                store.send(.error(error: .authorizationManagerAuthError(underlying: error), context: challenge, browserBaseURL: browserBaseURL))
            }
            
            isPerformingModalReqest = false
        }
    }
}

extension OwnID.CoreSDK.CurrentAccountManager {
    static func viewModelReducer(state: inout OwnID.CoreSDK.AccountManager.State, action: OwnID.CoreSDK.AccountManager.Action) -> [Effect<OwnID.CoreSDK.AccountManager.Action>] {
        switch action {
        case .didFinishRegistration:
            return []
            
        case .didFinishLogin:
            return []
            
        case .error:
            return []
        }
    }
}

extension OwnID.CoreSDK.AccountManager.Action: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .didFinishRegistration:
            return "didFinishRegistration"
            
        case .didFinishLogin:
            return "didFinishLogin"
            
        case .error:
            return "generalError"
        }
    }
}
