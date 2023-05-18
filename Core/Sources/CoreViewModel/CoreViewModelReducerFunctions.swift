import LocalAuthentication
import Combine

extension OwnID.CoreSDK.CoreViewModel {
    static func didFinishAuthManagerAction(_ state: State,
                                           _ fido2RegisterPayload: Encodable,
                                           _ browserBaseURL: String) -> [Effect<Action>] {
        [sendAuthRequest(session: state.session,
                         fido2Payload: fido2RegisterPayload,
                         browserBaseURL: browserBaseURL)]
    }
    
    static func createBrowserVM(for context: String,
                                browserURL: String,
                                loginId: OwnID.CoreSDK.LoginId?,
                                sdkConfigurationName: String,
                                store: Store<OwnID.CoreSDK.BrowserOpenerViewModel.State, OwnID.CoreSDK.BrowserOpenerViewModel.Action>,
                                redirectionURLString: OwnID.CoreSDK.RedirectionURLString?,
                                creationClosure: OwnID.CoreSDK.BrowserOpener.CreationClosure) -> OwnID.CoreSDK.BrowserOpener {
        let redirectionEncoded = (redirectionURLString ?? "").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let redirect = redirectionEncoded! + "?context=" + context
        let redirectParameter = "&redirectURI=" + redirect
        var urlString = browserURL
        if let loginId, loginId.settings.type == .email {
            var emailSet = CharacterSet.urlHostAllowed
            emailSet.remove("+")
            if let encoded = loginId.value.addingPercentEncoding(withAllowedCharacters: emailSet) {
                let emailParameter = "&e=" + encoded
                urlString.append(emailParameter)
            }
        }
        urlString.append(redirectParameter)
        let url = URL(string: urlString)!
        let vm = creationClosure(store, url, redirectionURLString ?? "")
        return vm
    }

    static func sendAuthRequest(session: APISessionProtocol,
                                fido2Payload: Encodable,
                                browserBaseURL: String) -> Effect<Action> {
        session.performAuthRequest(fido2Payload: fido2Payload)
            .receive(on: DispatchQueue.main)
            .map { _ in Action.authRequestLoaded }
            .catch { Just(Action.authManagerRequestFail(error: $0, browserBaseURL: browserBaseURL)) }
            .eraseToEffect()
    }
    
    static func sendStatusRequest(session: APISessionProtocol) -> Effect<Action> {
        session.performFinalStatusRequest()
            .map { Action.statusRequestLoaded(response: $0) }
            .catch { Just(Action.error($0)) }
            .eraseToEffect()
    }
}
