import AuthenticationServices
import Foundation
import Combine

private extension OwnID.CoreSDK {
    final class PasskeysAccountManager: NSObject, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
        public let eventPublisher = PassthroughSubject<Void, Never>()
        
        /// Needs to be brought from BE
        private var domain = "passwordless.staging.ownid.com"
        
        /// Needs to be generated new for every operation. In our case `challenge` = `context` . `context` can be fetched in init request with others settings.
        private var challenge = Data()
        private var serverURL: ServerURL!
        private var bag = Set<AnyCancellable>()
        
        var authenticationAnchor: ASPresentationAnchor {
            for scene in UIApplication.shared.connectedScenes {
                if scene.activationState == .foregroundActive {
                    return ((scene as? UIWindowScene)!.delegate as! UIWindowSceneDelegate).window!!
                }
            }
            fatalError()
        }
        
        func challengeDomainFetchedFromServer(domain: String, challenge: Data, serverURL: ServerURL) {
            self.domain = domain
            self.challenge = challenge
            self.serverURL = serverURL
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.signInWith()
                self.signUpWith(userName: "insert user name from registration here")
            }
        }
        
        func signUpWith(userName: String) {
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
            
            // Do we need to allow user use their passwords? `ASAuthorizationPasswordProvider`
            // Also allow the user to use a saved password, if they have one.
            let passwordCredentialProvider = ASAuthorizationPasswordProvider()
            let passwordRequest = passwordCredentialProvider.createRequest()
            
            // Pass in any mix of supported sign-in request types.
            let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest, passwordRequest ] )
            authController.delegate = self
            authController.presentationContextProvider = self
            
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
            let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
            
            let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge)
            
            // AutoFill-assisted requests only support ASAuthorizationPlatformPublicKeyCredentialAssertionRequest.
            let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest ] )
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performAutoFillAssistedRequests()
        }
        
        private func validateOnServer(_ userID: Data?, _ clientDataJSON: Data, _ rawData: Data?, _ signature: Data?) {
            let resultDictionary = [
                "credentialId": userID!.base64EncodedString(),
                "clientDataJSON": clientDataJSON.base64EncodedString(),
                "authenticatorData": rawData!.base64EncodedString(),
                "signature": String(data: signature!.base64EncodedData(), encoding: .utf8)!
            ]
            
            let jsonFields: [String : Any] = [
                "context": "OwnID.CoreSDK.shared.apiSession.context!",
                "nonce": "OwnID.CoreSDK.shared.apiSession.nonce!",
                "sessionVerifier": "OwnID.CoreSDK.shared.apiSession.sessionVerifier",
                "fido2Payload": resultDictionary
            ]
            let jsonData = try! JSONSerialization.data(withJSONObject: jsonFields, options: .prettyPrinted)
            
            
            let urlll = serverURL.appending(path: "passkeys/fido2/auth")
            
            var request = URLRequest(url: urlll)
            
            request.httpMethod = "POST"
            request.httpBody = jsonData
            request.setValue("https://demo.dev.ownid.com", forHTTPHeaderField: "Origin")
            URLSession.shared.dataTaskPublisher(for: request)
                .map { data, _ in
                    return data
                }
                .eraseToAnyPublisher()
                .decode(type: ClientConfiguration.self, decoder: JSONDecoder()) // Process ready to use session here
                .eraseToAnyPublisher()
                .replaceError(with: ClientConfiguration(logLevel: 4, passkeys: false, rpId: .none, passkeysAutofill: false))
                .sink(receiveValue: { response in
                    // Validate session and let user in
                    // After the server verifies the assertion, sign in the user.
                    self.didFinishSignIn()
                })
                .store(in: &bag)
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
                print("clientDataJSON: \(String(describing: String(data: clientDataJSON, encoding: .utf8)))")
                print("userID: \(String(describing: String(data: userID!.base64EncodedData(), encoding: .utf8)))")
                print("signature base64: \(String(describing: String(data: signature!.base64EncodedData(), encoding: .utf8)))")
                print("rawData base64: \(String(describing: String(data: rawData!.base64EncodedData(), encoding: .utf8)))")
                
                validateOnServer(userID, clientDataJSON, rawData, signature)
                
            case let passwordCredential as ASPasswordCredential:
                // What to do with this ASPasswordCredential?
                print("A password was provided: \(passwordCredential)")
                // Verify the userName and password with your service.
                let userName = passwordCredential.user
                let password = passwordCredential.password
                print(userName)
                print(password)
                
                // After the server verifies the userName and password, sign in the user.
                didFinishSignIn()
                
            default:
                // Ignore login with apple and other possible types?
                print("Received unknown authorization type.")
            }
        }
        
        public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Swift.Error) {
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
