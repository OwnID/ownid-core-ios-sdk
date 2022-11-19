import AuthenticationServices
import os

class AccountManager: NSObject, ASAuthorizationControllerDelegate {
    
    let domain = "ownid.com"//"passwordless.staging.ownid.com"
    let authenticationAnchor = ASPresentationAnchor()
    var currentAuthController: ASAuthorizationController?
    var isPerformingModalReqest = false
    
    func signInWith(preferImmediatelyAvailableCredentials: Bool) {
        currentAuthController?.cancel()
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
        
        let challenge = "CGLwDDkJMkqpyt9HcELWbg"//UUID().uuidString
        print("\(#function) 1️⃣ challenge:\(challenge)")
        
        let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge.data(using: .utf8)!)
        
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
        currentAuthController?.cancel()
        
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
        
        let challenge = UUID().uuidString
        print("\(#function) 1️⃣ challenge:\(challenge)")
        let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challenge.data(using: .utf8)!)
        
        let authController = ASAuthorizationController(authorizationRequests: [ assertionRequest ] )
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performAutoFillAssistedRequests()
        currentAuthController = authController
    }
    
    func signUpWith(userName: String) {
        currentAuthController?.cancel()
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
        
        let challenge = "luf836ZkvE6YVetg4prNsQ"//UUID().uuidString
        print("\(#function) 1️⃣ challenge:\(challenge)")
        let userID = userName //"yurii+v12@ownid.com"
        
        /// `createCredentialRegistrationRequest` also creates new credential if provided the same
        /// Registering a passkey with the same user ID as an existing one overwrites the existing passkey on the user’s devices.
        let registrationRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(challenge: challenge.data(using: .utf8)!,
                                                                                                  name: userID,
                                                                                                  userID: userID.data(using: .utf8)!)
        
        let authController = ASAuthorizationController(authorizationRequests: [ registrationRequest ] )
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performRequests()
        currentAuthController = authController
        isPerformingModalReqest = true
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        let logger = Logger()
        switch authorization.credential {
        case let credentialRegistration as ASAuthorizationPlatformPublicKeyCredentialRegistration:
            logger.log("A new passkey was registered")
            // Verify the attestationObject and clientDataJSON with your service.
            // The attestationObject contains the user's new public key to store and use for subsequent sign-ins.
            let attestationObject = credentialRegistration.rawAttestationObject?.base64urlEncodedString()
            let clientDataJSON = credentialRegistration.rawClientDataJSON
            let credentialID = credentialRegistration.credentialID.base64urlEncodedString()
            print("🏁")
            print("attestationObject: \(attestationObject!)")
            
            print("clientDataJSON Base64: \(clientDataJSON.base64urlEncodedString())")
            //            print("clientDataJSON: \(String(data: clientDataJSON, encoding: .utf8)!)")
            //            let json = try! JSONSerialization.jsonObject(with: clientDataJSON, options: []) as! [String: String]
            //            print("clientDataJSON challenge: \(json["challenge"]!.urlSafeBase64Decoded()!)")
            
            print("credentialID: \(credentialID)")
            
            // After the server verifies the registration and creates the user account, sign in the user with the new account.
            //            delegateController?.didFinishSignIn()
            
        case let credentialAssertion as ASAuthorizationPlatformPublicKeyCredentialAssertion:
            logger.log("A passkey was used to sign in")
            // Verify the below signature and clientDataJSON with your service for the given userID.
            let signature = credentialAssertion.signature.base64urlEncodedString()
            let rawAuthenticatorData = credentialAssertion.rawAuthenticatorData.base64urlEncodedString()
            let clientDataJSON = credentialAssertion.rawClientDataJSON
            let userID = credentialAssertion.userID.base64urlEncodedString()
            let credentialID = credentialAssertion.credentialID.base64urlEncodedString()
            print("🏁")
            print("signature: \(signature)")
            print("rawAuthenticatorData: \(rawAuthenticatorData)")
            print("clientDataJSON Base64: \(clientDataJSON.base64urlEncodedString())")
            //            print("clientDataJSON: \(String(data: clientDataJSON, encoding: .utf8)!)")
            print("userID: \(userID)")
            print("credentialID: \(credentialID)")
            
            // After the server verifies the assertion, sign in the user.
            //            delegateController?.didFinishSignIn()
            
        case let passwordCredential as ASPasswordCredential:
            logger.log("A password was provided")
            // Verify the userName and password with your service.
            let userName = passwordCredential.user
            let password = passwordCredential.password
            print("userName: \(userName)")
            print("password: \(password)")
            
            // After the server verifies the userName and password, sign in the user.
            //            delegateController?.didFinishSignIn()
            
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            logger.log("A ASAuthorizationAppleIDCredential was provided")
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            print("userIdentifier: \(userIdentifier)")
            print("fullName: \(String(describing: fullName))")
            print("email: \(email ?? "empty email")")
            
        default:
            fatalError("Received unknown authorization type.")
        }
        
        isPerformingModalReqest = false
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let logger = Logger()
        guard let authorizationError = error as? ASAuthorizationError else {
            isPerformingModalReqest = false
            logger.error("Unexpected authorization error: \(error.localizedDescription)")
            return
        }
        
        if authorizationError.code == .canceled {
            // Either the system doesn't find any credentials and the request ends silently, or the user cancels the request.
            // This is a good time to show a traditional login form, or ask the user to create an account.
            logger.log("Request canceled.")
            
            if isPerformingModalReqest {
                //                delegateController?.beginSignInAutofillSuggest()
            }
        } else {
            // Another ASAuthorization error.
            // Note: The userInfo dictionary contains useful information.
            logger.error("Error: \((error as NSError).userInfo)")
        }
        
        isPerformingModalReqest = false
    }
}