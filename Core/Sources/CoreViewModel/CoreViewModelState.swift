extension OwnID.CoreSDK.CoreViewModel {
    struct State: LoggingEnabled {
        let isLoggingEnabled: Bool
        var configuration: OwnID.CoreSDK.LocalConfiguration?
        
        let apiSessionCreationClosure: APISessionProtocol.CreationClosure
        let createAccountManagerClosure: OwnID.CoreSDK.AccountManager.CreationClosure
        let createBrowserOpenerClosure: OwnID.CoreSDK.BrowserOpener.CreationClosure
        
        let sdkConfigurationName: String
        var session: APISessionProtocol!
        let email: OwnID.CoreSDK.Email?
        let type: OwnID.CoreSDK.RequestType
        let supportedLanguages: OwnID.CoreSDK.Languages
        
        var browserViewModelStore: Store<OwnID.CoreSDK.BrowserOpenerViewModel.State, OwnID.CoreSDK.BrowserOpenerViewModel.Action>!
        var browserViewModel: OwnID.CoreSDK.BrowserOpener?
        
        var authManagerStore: Store<OwnID.CoreSDK.AccountManager.State, OwnID.CoreSDK.AccountManager.Action>!
        var authManager: OwnID.CoreSDK.AccountManager?
        var oneTimePasswordStore: Store<OwnID.UISDK.OneTimePasswordView.ViewState, OwnID.UISDK.OneTimePasswordView.Action>!
        
        var shouldStartFlowOnConfigurationReceive = true
    }
}
