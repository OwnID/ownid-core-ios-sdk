extension OwnID.CoreSDK.CoreViewModel {
    
    typealias ApiSessionCreationClosure = (_ initURL: OwnID.CoreSDK.ServerURL,
                                           _ statusURL: OwnID.CoreSDK.ServerURL,
                                           _ finalStatusURL: OwnID.CoreSDK.ServerURL,
                                           _ authURL: OwnID.CoreSDK.ServerURL,
                                           _ supportedLanguages: OwnID.CoreSDK.Languages) -> APISessionProtocol
    
    static var defaultAPISession: ApiSessionCreationClosure {
        { initURL,
            statusURL,
            finalStatusURL,
            authURL,
            supportedLanguages in
            OwnID.CoreSDK.APISession(initURL: initURL,
                                     statusURL: statusURL,
                                     finalStatusURL: finalStatusURL,
                                     authURL: authURL,
                                     supportedLanguages: supportedLanguages)
        }
    }
    
    struct State: LoggingEnabled {
        let isLoggingEnabled: Bool
        var configuration: OwnID.CoreSDK.LocalConfiguration?
        let apiSessionCreationClosure: ApiSessionCreationClosure
        
        let sdkConfigurationName: String
        var session: APISessionProtocol!
        let email: OwnID.CoreSDK.Email?
        let type: OwnID.CoreSDK.RequestType
        let supportedLanguages: OwnID.CoreSDK.Languages
        
        var browserViewModelStore: Store<OwnID.CoreSDK.BrowserOpenerViewModel.State, OwnID.CoreSDK.BrowserOpenerViewModel.Action>!
        var browserViewModel: BrowserOpener?
        
        var authManagerStore: Store<OwnID.CoreSDK.AccountManager.State, OwnID.CoreSDK.AccountManager.Action>!
        var authManager: OwnID.CoreSDK.AccountManager?
        
        var shouldStartFlowOnConfigurationReceive = true
    }
}
