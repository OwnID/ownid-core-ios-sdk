import Foundation
import Combine

extension OwnID.CoreSDK.CoreViewModel {
    class WebAppStep: BaseStep {
        private let step: Step
        
        init(step: Step) {
            self.step = step
        }
        
        override func run(state: inout OwnID.CoreSDK.CoreViewModel.State) -> [Effect<OwnID.CoreSDK.CoreViewModel.Action>] {
            guard let urlString = step.webAppData?.url else {
                let message = OwnID.CoreSDK.ErrorMessage.dataIsMissing
                return errorEffect(.coreLog(entry: .errorEntry(Self.self),
                                            error: .userError(errorModel: OwnID.CoreSDK.UserErrorModel(message: message))))
            }
            
            guard let loginIdSettings = state.configuration?.loginIdSettings else {
                let message = OwnID.CoreSDK.ErrorMessage.noLocalConfig
                return errorEffect(.coreLog(entry: .errorEntry(Self.self),
                                            error: .userError(errorModel: OwnID.CoreSDK.UserErrorModel(message: message))))
            }
            
            let viewModel = createBrowserVM(for: state.context,
                                            browserURL: urlString,
                                            loginId: OwnID.CoreSDK.LoginId(value: state.loginId, settings: loginIdSettings),
                                            sdkConfigurationName: state.sdkConfigurationName,
                                            store: state.browserViewModelStore,
                                            redirectionURLString: state.configuration?.redirectionURL,
                                            creationClosure: state.createBrowserOpenerClosure)
            state.browserViewModel = viewModel
            return []
        }
        
        private func createBrowserVM(for context: String,
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
}
