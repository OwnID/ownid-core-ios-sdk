import AuthenticationServices
import Foundation
import os
import Combine

public extension OwnID.CoreSDK {
    final class PasskeysAccountManager: NSObject, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
        var domain = "passwordless.staging.ownid.com"
        #warning("generate challenge each time new")
        var challenge = Data()
        public let eventPublisher = PassthroughSubject<Void, Never>()
        private var bag = Set<AnyCancellable>()
        var serverURL: ServerURL!
        
        var authenticationAnchor: ASPresentationAnchor {
            for scene in UIApplication.shared.connectedScenes {
                if scene.activationState == .foregroundActive {
                    return ((scene as? UIWindowScene)!.delegate as! UIWindowSceneDelegate).window!!
                }
            }
            fatalError()
        }
        
        func start() {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.signInWith()
//                self.signUpWith()
            }
        }
        
        func signUpWith(userName: String = "yuroomdk@kndke.fmnek") {
            print(#function)
            let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
            
            // Fetch the challenge from the server. The challenge needs to be unique for each request.
            // The userID is the identifier for the user's account.
            let userID = Data(UUID().uuidString.utf8)
            
            let registrationRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(challenge: challenge,
                                                                                                      name: userName,
                                                                                                      userID: userID)
            
            // Use only ASAuthorizationPlatformPublicKeyCredentialRegistrationRequests or
            // ASAuthorizationSecurityKeyPublicKeyCredentialRegistrationRequests here.
            let authController = ASAuthorizationController(authorizationRequests: [ registrationRequest ] )
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performRequests()
        }
        
        public func signInWith(preferImmediatelyAvailableCredentials: Bool = true) {
            if challenge.isEmpty {
                return
            }
            let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
            
            let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge)
            
#warning("check password")
            // Also allow the user to use a saved password, if they have one.
            let passwordCredentialProvider = ASAuthorizationPasswordProvider()
            let passwordRequest = passwordCredentialProvider.createRequest()
            
            // Pass in any mix of supported sign-in request types.
            let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest, passwordRequest ] )
            authController.delegate = self
            authController.presentationContextProvider = self
            
#warning("check turned on and off")
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
        }
        
        public func beginAutoFillAssistedPasskeySignIn() {
            
//                if challenge.isEmpty {
//                    return
//                }
//            let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
//            
//            let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge)
//            
//            // AutoFill-assisted requests only support ASAuthorizationPlatformPublicKeyCredentialAssertionRequest.
//            let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest ] )
//            authController.delegate = self
//            authController.presentationContextProvider = self
//            authController.performAutoFillAssistedRequests()
        }
        
        public func authorizationController(controller: ASAuthorizationController,
                                            didCompleteWithAuthorization authorization: ASAuthorization) {
            switch authorization.credential {
                
            case let credentialAssertion as ASAuthorizationPlatformPublicKeyCredentialAssertion:
                print("A passkey was used to sign in: \(credentialAssertion)")
                // Verify the below signature and clientDataJSON with your service for the given userID.
                let signature = credentialAssertion.signature
                let rawData = credentialAssertion.rawAuthenticatorData
                let clientDataJSON = credentialAssertion.rawClientDataJSON
                let userID = credentialAssertion.userID
                print("clientDataJSON: \(String(data: clientDataJSON, encoding: .utf8))")
                print("userID: \(String(data: userID!, encoding: .utf8))")
                print("signature base64: \(String(data: signature!.base64EncodedData(), encoding: .utf8))")
                print("rawData base64: \(String(data: rawData!.base64EncodedData(), encoding: .utf8))")
                
                let resultDictionary = ["credentialId": userID!.base64EncodedString(), "clientDataJSON": clientDataJSON.base64EncodedString(), "authenticatorData": rawData!.base64EncodedString(), "signature": String(data: signature!.base64EncodedData(), encoding: .utf8)!]
                let jsonFields: [String : Any] = ["context": OwnID.CoreSDK.shared.apiSession.context, "nonce": OwnID.CoreSDK.shared.apiSession.nonce, "sessionVerifier": OwnID.CoreSDK.shared.apiSession.sessionVerifier, "fido2Payload": resultDictionary]
                let jsonData = try! JSONSerialization.data(withJSONObject: jsonFields, options: .prettyPrinted)
                
                
                let urlll = serverURL.appending(path: "passkeys/fido2/auth")
                
                var request = URLRequest(url: urlll)

                request.httpMethod = "POST"
                request.httpBody = jsonData
                request.setValue("https://demo.dev.ownid.com", forHTTPHeaderField: "Origin")
                print("performing query for context: \(String(data: challenge, encoding: .utf8))")
                URLSession.shared.dataTaskPublisher(for: request)
                        .map { data, obj in
                            
                            #warning("what is here, should be session to log in")
                            print(obj.expectedContentLength)
                            print(String(data: data, encoding: .utf8))
                            return data
                        }
                        .eraseToAnyPublisher()
                        .decode(type: ClientConfiguration.self, decoder: JSONDecoder())
                        .eraseToAnyPublisher()
                        .replaceError(with: ClientConfiguration(logLevel: 4, passkeys: false, rpId: .none, passkeysAutofill: false))
                        .sink(receiveValue: { response in
                            #warning("validate session and let user in")
                            
                            // After the server verifies the assertion, sign in the user.
                            self.didFinishSignIn()
                        })
                        .store(in: &bag)
                
                
                
                
                
                
                
                
                
#warning("what to do with this stuff")
            case let passwordCredential as ASPasswordCredential:
                print("A password was provided: \(passwordCredential)")
                // Verify the userName and password with your service.
                let userName = passwordCredential.user
                let password = passwordCredential.password
                print(userName)
                print(password)
                
                // After the server verifies the userName and password, sign in the user.
                didFinishSignIn()
                
            default:
#warning("we can somehow here check for login with apple")
                print("Received unknown authorization type.")
            }
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            print(#function)
            guard let authorizationError = error as? ASAuthorizationError else {
                print("Unexpected authorization error: \(error.localizedDescription)")
                return
            }
            
            if authorizationError.code == .canceled {
                // Either the system doesn't find any credentials and the request ends silently, or the user cancels the request.
                // This is a good time to show a traditional login form, or ask the user to create an account.
                print("Request canceled.")
            } else {
                // Another ASAuthorization error.
                // Note: The userInfo dictionary contains useful information.
                print("Another ASAuthorization error: \((error as NSError).userInfo)")
            }
        }
        
        public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            authenticationAnchor
        }
        
        func didFinishSignIn() {
            eventPublisher.send(())
        }
    }
}
