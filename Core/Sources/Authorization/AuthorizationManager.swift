import AuthenticationServices
import os

extension OwnID.CoreSDK.AccountManager {
    struct State: LoggingEnabled {
        init(isLoggingEnabled: Bool, domain: String, challenge: String) {
            self.isLoggingEnabled = isLoggingEnabled
            self.domain = domain
            self.challenge = challenge
        }
        
        let isLoggingEnabled: Bool
        let domain: String //"ownid.com"//"passwordless.staging.ownid.com"
        let challenge: String
        
        fileprivate var challengeData: Data {
            challenge.data(using: .utf8)!
        }
    }
    
    enum Action {
        case didFinishRegistration
        case didFinishLogin
        case didFinishPasswordLogin
        case didFinishAppleLogin
        case credintialsNotFoundOrCanlelledByUser
        case error(error: Error)
    }
}

extension OwnID.CoreSDK {
    final class AccountManager: NSObject, ASAuthorizationControllerDelegate {
        private var store: Store<State, Action>
        let authenticationAnchor = ASPresentationAnchor()
        
        private var currentAuthController: ASAuthorizationController?
        private var isPerformingModalReqest = false
        
        init(store: Store<State, Action>) {
            self.store = store
        }
        
        func signInWith(preferImmediatelyAvailableCredentials: Bool) {
            currentAuthController?.cancel()
            let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: store.value.domain)
            
            let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: store.value.challengeData)
            
            // Also allow the user to use a saved password, if they have one.
            let passwordCredentialProvider = ASAuthorizationPasswordProvider()
            let passwordRequest = passwordCredentialProvider.createRequest()
            
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let appleIDRequest = appleIDProvider.createRequest()
            appleIDRequest.requestedScopes = [.fullName, .email]
            
            let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest, passwordRequest, appleIDRequest ] )
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
        
        func beginAutoFillAssistedPasskeySignIn() {
            fatalError("For now autofill is not supported right here, we need some other way to enable this as we need new challenge for this")
            currentAuthController?.cancel()
            
            let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: store.value.domain)
            let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: store.value.challengeData)
            
            let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest ] )
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performAutoFillAssistedRequests()
            currentAuthController = authController
        }
        
        func signUpWith(userName: String) {
            currentAuthController?.cancel()
            let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: store.value.domain)
            
            /// `createCredentialRegistrationRequest` also creates new credential if provided the same
            /// Registering a passkey with the same user ID as an existing one overwrites the existing passkey on the user’s devices.
            let registrationRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(challenge: store.value.challengeData,
                                                                                                      name: userName,
                                                                                                      userID: userName.data(using: .utf8)!)
            
            let authController = ASAuthorizationController(authorizationRequests: [ registrationRequest ] )
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performRequests()
            currentAuthController = authController
            isPerformingModalReqest = true
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            switch authorization.credential {
            case let credentialRegistration as ASAuthorizationPlatformPublicKeyCredentialRegistration:
                print("A new passkey was registered")
                // Verify the attestationObject and clientDataJSON with your service.
                // The attestationObject contains the user's new public key to store and use for subsequent sign-ins.
                let attestationObject = credentialRegistration.rawAttestationObject?.base64urlEncodedString()
                let clientDataJSON = credentialRegistration.rawClientDataJSON
                let credentialID = credentialRegistration.credentialID.base64urlEncodedString()
                print("attestationObject: \(attestationObject!)")
                
                print("clientDataJSON Base64: \(clientDataJSON.base64urlEncodedString())")
                //            print("clientDataJSON: \(String(data: clientDataJSON, encoding: .utf8)!)")
                //            let json = try! JSONSerialization.jsonObject(with: clientDataJSON, options: []) as! [String: String]
                //            print("clientDataJSON challenge: \(json["challenge"]!.urlSafeBase64Decoded()!)")
                
                print("credentialID: \(credentialID)")
                
                // After the server verifies the registration and creates the user account, sign in the user with the new account.
                store.send(.didFinishRegistration)
                
            case let credentialAssertion as ASAuthorizationPlatformPublicKeyCredentialAssertion:
                print("A passkey was used to sign in")
                // Verify the below signature and clientDataJSON with your service for the given userID.
                let signature = credentialAssertion.signature.base64urlEncodedString()
                let rawAuthenticatorData = credentialAssertion.rawAuthenticatorData.base64urlEncodedString()
                let clientDataJSON = credentialAssertion.rawClientDataJSON
                let userID = credentialAssertion.userID.base64urlEncodedString()
                let credentialID = credentialAssertion.credentialID.base64urlEncodedString()
                print("signature: \(signature)")
                print("rawAuthenticatorData: \(rawAuthenticatorData)")
                print("clientDataJSON Base64: \(clientDataJSON.base64urlEncodedString())")
                //            print("clientDataJSON: \(String(data: clientDataJSON, encoding: .utf8)!)")
                print("userID: \(userID)")
                print("credentialID: \(credentialID)")
                
                // After the server verifies the assertion, sign in the user.
                store.send(.didFinishLogin)
                
            case let passwordCredential as ASPasswordCredential:
                print("A password was provided")
                // Verify the userName and password with your service.
                let userName = passwordCredential.user
                let password = passwordCredential.password
                print("userName: \(userName)")
                print("password: \(password)")
                
                // After the server verifies the userName and password, sign in the user.
                store.send(.didFinishPasswordLogin)
                
            case let appleIDCredential as ASAuthorizationAppleIDCredential:
                print("A ASAuthorizationAppleIDCredential was provided")
                let userIdentifier = appleIDCredential.user
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email
                
                print("userIdentifier: \(userIdentifier)")
                print("fullName: \(String(describing: fullName))")
                print("email: \(email ?? "empty email")")
                store.send(.didFinishAppleLogin)
                
            default:
                fatalError("Received unknown authorization type.")
            }
            
            //            isPerformingModalReqest = false
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            guard let authorizationError = error as? ASAuthorizationError else {
                isPerformingModalReqest = false
                store.send(.error(error: error))
                return
            }
            
            if authorizationError.code == .canceled {
                // Either the system doesn't find any credentials and the request ends silently, or the user cancels the request.
                // This is a good time to show a traditional login form, or ask the user to create an account.
                
                if isPerformingModalReqest {
                    store.send(.credintialsNotFoundOrCanlelledByUser)
                }
            } else {
                // Another ASAuthorization error.
                // Note: The userInfo dictionary contains useful information.
                print("Error: \((error as NSError).userInfo)")
                store.send(.error(error: error))
            }
            
            isPerformingModalReqest = false
        }
    }
}

//                               extension OwnID.CoreSDK.AccountManager {
//                        static func viewModelReducer(state: inout State, action: Action) -> [Effect<Action>] {
//                            switch action {
//        case .signInWith(preferImmediatelyAvailableCredentials: let preferImmediatelyAvailableCredentials):
//            state.currentAuthController?.cancel()
//            let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: state.domain)
//
//            let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: state.challengeData)
//
//            // Also allow the user to use a saved password, if they have one.
//            let passwordCredentialProvider = ASAuthorizationPasswordProvider()
//            let passwordRequest = passwordCredentialProvider.createRequest()
//
//            let appleIDProvider = ASAuthorizationAppleIDProvider()
//            let appleIDRequest = appleIDProvider.createRequest()
//            appleIDRequest.requestedScopes = [.fullName, .email]
//
//            let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest, passwordRequest, appleIDRequest ] )
//            authController.delegate = self
//            authController.presentationContextProvider = self
//
//            state.currentAuthController = authController
//
//            if preferImmediatelyAvailableCredentials {
//                // If credentials are available, presents a modal sign-in sheet.
//                // If there are no locally saved credentials, no UI appears and
//                // the system passes ASAuthorizationError.Code.canceled to call
//                // `AccountManager.authorizationController(controller:didCompleteWithError:)`.
//                authController.performRequests(options: .preferImmediatelyAvailableCredentials)
//            } else {
//                // If credentials are available, presents a modal sign-in sheet.
//                // If there are no locally saved credentials, the system presents a QR code to allow signing in with a
//                // passkey from a nearby device.
//                authController.performRequests()
//            }
//
//            state.isPerformingModalReqest = true

//        case .signUpWith(userName: let userName):
//            <#code#>
//        case .beginAutoFillAssistedPasskeySignIn:
//            <#code#>
//                            case .didFinishRegistration:
//                                <#code#>
//                            case .didFinishLogin:
//                                <#code#>
//                            case .didFinishPasswordLogin:
//                                <#code#>
//                            case .didFinishAppleLogin:
//                                <#code#>
//                            case .credintialsNotFoundOrCanlelledByUser:
//                                <#code#>
//                            case .error(error: let error):
//                                <#code#>
//                            }
//                        }
//                    }
