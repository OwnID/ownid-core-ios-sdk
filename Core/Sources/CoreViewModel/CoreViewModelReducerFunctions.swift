import LocalAuthentication
import Combine

extension OwnID.CoreSDK.CoreViewModel {
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
}
