import AuthenticationServices
import os

extension OwnID.CoreSDK.AccountManager.Action: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .didFinishRegistration:
            return "didFinishRegistration"
            
        case .didFinishLogin:
            return "didFinishLogin"
            
        case .didFinishPasswordLogin:
            return "didFinishPasswordLogin"
            
        case .didFinishAppleLogin:
            return "didFinishAppleLogin"
            
        case .credintialsNotFoundOrCanlelledByUser:
            return "credintialsNotFoundOrCanlelledByUser"
            
        case .error(let error):
            return error.localizedDescription
        }
    }
}

extension OwnID.CoreSDK.AccountManager {
    struct State: LoggingEnabled {
        init(isLoggingEnabled: Bool) {
            self.isLoggingEnabled = isLoggingEnabled
        }
        
        let isLoggingEnabled: Bool
    }
    
    enum Action {
        case didFinishRegistration(origin: String, fido2RegisterPayload: OwnID.CoreSDK.Fido2RegisterPayload)
        case didFinishLogin(origin: String, fido2LoginPayload: OwnID.CoreSDK.Fido2LoginPayload)
        case didFinishPasswordLogin
        case didFinishAppleLogin
        case credintialsNotFoundOrCanlelledByUser
        case error(error: OwnID.CoreSDK.Error)
    }
}

@available(iOS 16.0, *)
extension OwnID.CoreSDK.AccountManager: ASAuthorizationControllerDelegate { }
    
extension OwnID.CoreSDK {
    final class AccountManager: NSObject {
        let authenticationAnchor = ASPresentationAnchor()
        
        private let store: Store<State, Action>
        private let domain: String
        private let challenge: String
        
        private var challengeData: Data {
            challenge.data(using: .utf8)!
        }
        
        private var currentAuthController: ASAuthorizationController?
        private var isPerformingModalReqest = false
        
        init(store: Store<State, Action>, domain: String, challenge: String) {
            self.store = store
            self.domain = domain //"ownid.com"//"passwordless.staging.ownid.com"
            self.challenge = challenge
        }
        
        @available(iOS 16.0, *)
        func signInWith(preferImmediatelyAvailableCredentials: Bool) {
            currentAuthController?.cancel()
            let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
            
            let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challengeData)
            
            // Also allow the user to use a saved password, if they have one.
            let passwordCredentialProvider = ASAuthorizationPasswordProvider()
            let passwordRequest = passwordCredentialProvider.createRequest()
            
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let appleIDRequest = appleIDProvider.createRequest()
            appleIDRequest.requestedScopes = [.fullName, .email]
            
            let requests = [ assertionRequest, passwordRequest, appleIDRequest ]
            let authController = ASAuthorizationController(authorizationRequests: requests)
            authController.delegate = self
            authController.presentationContextProvider = self
            
            currentAuthController = authController
            
            if preferImmediatelyAvailableCredentials {
                // If credentials are available, presents a modal sign-in sheet.
                // If there are no locally saved credentials, no UI appears and
                // the system passes ASAuthorizationError.Code.canceled to call
                // `AccountManager.authorizationController(controller:didCompleteWithError:)`.
                authController.performRequests(options: .preferImmediatelyAvailableCredentials)
            } else {
                // If credentials are available, presents a modal sign-in sheet.
                // If there are no locally saved credentials, the system presents a QR code to allow signing in with a
                // passkey from a nearby device.
                authController.performRequests()
            }
            
            isPerformingModalReqest = true
        }
        
        @available(iOS 16.0, *)
        func beginAutoFillAssistedPasskeySignIn() {
            #warning("fatal error")
            fatalError("For now autofill is not supported right here, we need some other way to enable this as we need new challenge for this")
            currentAuthController?.cancel()
            
            let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
            let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challengeData)
            
            let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest ] )
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
            
            let authController = ASAuthorizationController(authorizationRequests: [ registrationRequest ] )
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
                    store.send(.error(error: .authorizationManagerDataMissing))
                    return
                }
                
                let clientDataJSON = credentialRegistration.rawClientDataJSON.base64urlEncodedString()
                let credentialID = credentialRegistration.credentialID.base64urlEncodedString()
                
                // After the server verifies the registration and creates the user account, sign in the user with the new account.
                
                let payload = OwnID.CoreSDK.Fido2RegisterPayload(credentialId: credentialID,
                                                                 clientDataJSON: clientDataJSON,
                                                                 attestationObject: attestationObject)
                store.send(.didFinishRegistration(origin: domain, fido2RegisterPayload: payload))
                
            case let credentialAssertion as ASAuthorizationPlatformPublicKeyCredentialAssertion:
                // Verify the below signature and clientDataJSON with your service for the given userID.
                let signature = credentialAssertion.signature.base64urlEncodedString()
                let rawAuthenticatorData = credentialAssertion.rawAuthenticatorData.base64urlEncodedString()
                let clientDataJSON = credentialAssertion.rawClientDataJSON
                let userID = credentialAssertion.userID
                let credentialID = credentialAssertion.credentialID.base64urlEncodedString()
                
                let payload = OwnID.CoreSDK.Fido2LoginPayload(credentialId: credentialID,
                                                              clientDataJSON: clientDataJSON.base64urlEncodedString(),
                                                              authenticatorData: rawAuthenticatorData,
                                                              signature: signature)
                store.send(.didFinishLogin(origin: domain, fido2LoginPayload: payload))
                
            case let passwordCredential as ASPasswordCredential:
                // Verify the userName and password with your service.
                let userName = passwordCredential.user
                let password = passwordCredential.password
                
                // After the server verifies the userName and password, sign in the user.
                store.send(.didFinishPasswordLogin)
                
            case let appleIDCredential as ASAuthorizationAppleIDCredential:
                #warning("remove all prints")
                print("A ASAuthorizationAppleIDCredential was provided")
                let userIdentifier = appleIDCredential.user
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email
                store.send(.didFinishAppleLogin)
                
            default:
                store.send(.error(error: .authorizationManagerUnknownAuthType))
            }
            
            isPerformingModalReqest = false
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Swift.Error) {
            guard let authorizationError = error as? ASAuthorizationError else {
                isPerformingModalReqest = false
                store.send(.error(error: .authorizationManagerGeneralError(error: error)))
                return
            }
            
            if authorizationError.code == .canceled {
                // Either the system doesn't find any credentials and the request ends silently, or the user cancels the request.
                // This is a good time to show a traditional login form, or ask the user to create an account.
                
                if isPerformingModalReqest {
                    store.send(.credintialsNotFoundOrCanlelledByUser)
                }
            } else {
                #warning("add to each error loggin with context")
                store.send(.error(error: .authorizationManagerAuthError(userInfo: (error as NSError).userInfo)))
            }
            
            isPerformingModalReqest = false
        }
    }
}

extension OwnID.CoreSDK.AccountManager {
    static func viewModelReducer(state: inout State, action: Action) -> [Effect<Action>] {
        switch action {
        case .didFinishRegistration:
            return []
            
        case .didFinishLogin:
            return []
            
        case .didFinishPasswordLogin:
            return []
            
        case .didFinishAppleLogin:
            return []
            
        case .credintialsNotFoundOrCanlelledByUser:
            return []
            
        case .error:
            return []
        }
    }
}
