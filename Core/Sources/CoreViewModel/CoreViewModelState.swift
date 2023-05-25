extension OwnID.CoreSDK.CoreViewModel {
    struct State: LoggingEnabled {
        let isLoggingEnabled: Bool
        var configuration: OwnID.CoreSDK.LocalConfiguration?
        
        let createAccountManagerClosure: OwnID.CoreSDK.AccountManager.CreationClosure
        let createBrowserOpenerClosure: OwnID.CoreSDK.BrowserOpener.CreationClosure
        
        let sdkConfigurationName: String
        let loginId: String
        let type: OwnID.CoreSDK.RequestType
        let supportedLanguages: OwnID.CoreSDK.Languages
        
        var browserViewModelStore: Store<OwnID.CoreSDK.BrowserOpenerViewModel.State, OwnID.CoreSDK.BrowserOpenerViewModel.Action>!
        var browserViewModel: OwnID.CoreSDK.BrowserOpener?
        
        var authManagerStore: Store<OwnID.CoreSDK.AccountManager.State, OwnID.CoreSDK.AccountManager.Action>!
        var authManager: OwnID.CoreSDK.AccountManager?
        
        var oneTimePasswordStore: Store<OwnID.UISDK.OneTimePassword.ViewState, OwnID.UISDK.OneTimePassword.Action>!
        
        var idCollectViewStore: Store<OwnID.UISDK.InstantConnent.ViewState, OwnID.UISDK.InstantConnent.Action>!
        
        var shouldStartFlowOnConfigurationReceive = true
        
        var sessionVerifier: OwnID.CoreSDK.SessionVerifier!
        var session: OwnID.CoreSDK.SessionService!
        var stopUrl: URL!
        var finalUrl: URL!
        var context: OwnID.CoreSDK.Context!
        
        #warning("temporary desicion until move auth manager methods to FidoAuthStep class")
        var fidoStep: FidoAuthStep!
        var otpStep: OTPAuthStep!
        var idCollectStep: IdCollectStep!
    }
}
