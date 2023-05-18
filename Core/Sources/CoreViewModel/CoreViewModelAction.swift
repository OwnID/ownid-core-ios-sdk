extension OwnID.CoreSDK.CoreViewModel {
    enum Action {
        case cancelled
        case error(OwnID.CoreSDK.CoreErrorLogWrapper)
        case addErrorToInternalStates(OwnID.CoreSDK.Error) // this is needed for flows when error is thrown and flow does not immitiately goes to error. If auth manager throws error, we continue to next steps and log error to our states only
        
        case addToState(browserViewModelStore: Store<OwnID.CoreSDK.BrowserOpenerViewModel.State, OwnID.CoreSDK.BrowserOpenerViewModel.Action>,
                        authStore: Store<OwnID.CoreSDK.AccountManager.State, OwnID.CoreSDK.AccountManager.Action>,
                        oneTimePasswordStore: Store<OwnID.UISDK.OneTimePassword.ViewState, OwnID.UISDK.OneTimePassword.Action>)
        case addToStateConfig(config: OwnID.CoreSDK.LocalConfiguration)
        case addToStateShouldStartInitRequest(value: Bool)
        
        case sendInitialRequest
        case initialRequestLoaded(response: OwnID.CoreSDK.Init.Response)
        case idCollect
        case fido2Authorize(step: OwnID.CoreSDK.Step)
        case authManagerRequestFail(error: OwnID.CoreSDK.CoreErrorLogWrapper, browserBaseURL: String)
        case sendStatusRequest
        case browserCancelled
        case oneTimePasswordCancelled
        case authManagerCancelled
        case authRequestLoaded
        case oneTimePassword
        case statusRequestLoaded(response: OwnID.CoreSDK.Payload)
        case browserVM(OwnID.CoreSDK.BrowserOpenerViewModel.Action)
        case oneTimePasswordView(OwnID.UISDK.OneTimePassword.Action)
        case authManager(OwnID.CoreSDK.AccountManager.Action)
        case stopRequestLoaded
    }
}
