import AuthenticationServices

extension OwnID.CoreSDK.BrowserOpenerViewModel {
    final class ASWebAuthenticationPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
        
        // MARK: - ASWebAuthenticationPresentationContextProviding
        
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            ASPresentationAnchor()
        }
    }
}
