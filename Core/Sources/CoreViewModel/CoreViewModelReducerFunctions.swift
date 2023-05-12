import LocalAuthentication
import Combine

extension OwnID.CoreSDK.CoreViewModel {
    static var isPasskeysSupported: Bool {
        let isLeastPasskeysSupportediOS = ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 16, minorVersion: 0, patchVersion: 0))
        var isBiometricsAvailable = false
        let authContext = LAContext()
        let _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch authContext.biometryType {
        case .none:
            break
        case .touchID:
            isBiometricsAvailable = true
        case .faceID:
            isBiometricsAvailable = true
        @unknown default:
            print("please update biometrics types")
        }
        let isPasscodeAvailable = LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        let isPasskeysSupported = isLeastPasskeysSupportediOS && (isBiometricsAvailable || isPasscodeAvailable)
        return isPasskeysSupported
    }
    static func didFinishAuthManagerAction(_ state: State,
                                           _ fido2RegisterPayload: Encodable,
                                           _ browserBaseURL: String) -> [Effect<Action>] {
        [sendAuthRequest(session: state.session,
                         fido2Payload: fido2RegisterPayload,
                         browserBaseURL: browserBaseURL)]
    }
    
    static func createBrowserVM(for context: String,
                                browserURL: String,
                                loginId: String,
                                type: OwnID.CoreSDK.LoginIdSettings.LoginIdType,
                                sdkConfigurationName: String,
                                store: Store<OwnID.CoreSDK.BrowserOpenerViewModel.State, OwnID.CoreSDK.BrowserOpenerViewModel.Action>,
                                redirectionURLString: OwnID.CoreSDK.RedirectionURLString?,
                                creationClosure: OwnID.CoreSDK.BrowserOpener.CreationClosure) -> OwnID.CoreSDK.BrowserOpener {
        let redirectionEncoded = (redirectionURLString ?? "").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let redirect = redirectionEncoded! + "?context=" + context
        let redirectParameter = "&redirectURI=" + redirect
        var urlString = browserURL
        //TODO: check it
        if type == .email {
            var emailSet = CharacterSet.urlHostAllowed
            emailSet.remove("+")
            if let encoded = loginId.addingPercentEncoding(withAllowedCharacters: emailSet) {
                let emailParameter = "&e=" + encoded
                urlString.append(emailParameter)
            }
        }
        urlString.append(redirectParameter)
        let url = URL(string: urlString)!
        let vm = creationClosure(store, url, redirectionURLString ?? "")
        return vm
    }
    
    static func errorEffect(_ error: OwnID.CoreSDK.CoreErrorLogWrapper) -> [Effect<Action>] {
        [Just(.error(error)).eraseToEffect()]
    }
    
    static func sendInitialRequest(requestData: OwnID.CoreSDK.Init.RequestData,
                                   session: APISessionProtocol) -> Effect<Action> {
        session.performInitRequest(requestData: requestData)
            .receive(on: DispatchQueue.main)
            .map { Action.initialRequestLoaded(response: $0) }
            .catch { Just(Action.error($0)) }
            .eraseToEffect()
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
