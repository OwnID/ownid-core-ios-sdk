import AuthenticationServices

@available(iOS 16.0, *)
extension OwnID.CoreSDK.AccountManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        authenticationAnchor
    }
}
