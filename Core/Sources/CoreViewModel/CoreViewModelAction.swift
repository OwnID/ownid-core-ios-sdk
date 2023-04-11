extension OwnID.CoreSDK.CoreViewModel {
    enum Action {
        case addToState(browserViewModelStore: Store<OwnID.CoreSDK.BrowserOpenerViewModel.State, OwnID.CoreSDK.BrowserOpenerViewModel.Action>,
                        authStore: Store<OwnID.CoreSDK.AccountManager.State, OwnID.CoreSDK.AccountManager.Action>,
                        oneTimePasswordStore: Store<OwnID.UISDK.OneTimePasswordView.ViewState, OwnID.UISDK.OneTimePasswordView.Action>)
        case addToStateConfig(config: OwnID.CoreSDK.LocalConfiguration)
        case addToStateShouldStartInitRequest(value: Bool)
        case sendInitialRequest
        case initialRequestLoaded(response: OwnID.CoreSDK.Init.Response)
        case authManagerRequestFail(error: OwnID.CoreSDK.CoreErrorLogWrapper, browserBaseURL: String)
        case error(OwnID.CoreSDK.CoreErrorLogWrapper)
        case sendStatusRequest
        case browserCancelled
        case oneTimePasswordCancelled
        case cancelled
        case authManagerCancelled
        case authRequestLoaded
        case oneTimePassword
        case statusRequestLoaded(response: OwnID.CoreSDK.Payload)
        case browserVM(OwnID.CoreSDK.BrowserOpenerViewModel.Action)
        case oneTimePasswordView(OwnID.UISDK.OneTimePasswordView.Action)
        case authManager(OwnID.CoreSDK.AccountManager.Action)
        case addErrorToInternalStates(OwnID.CoreSDK.Error)
    }
}
