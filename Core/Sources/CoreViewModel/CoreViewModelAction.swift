extension OwnID.CoreSDK.CoreViewModel {
    enum Action {
        case cancelled
        case error(OwnID.CoreSDK.CoreErrorLogWrapper)
        case addErrorToInternalStates(OwnID.CoreSDK.Error) // this is needed for flows when error is thrown and flow does not immitiately goes to error. If auth manager throws error, we continue to next steps and log error to our states only
        
        case addToState(browserViewModelStore: Store<OwnID.CoreSDK.BrowserOpenerViewModel.State, OwnID.CoreSDK.BrowserOpenerViewModel.Action>,
                        authStore: Store<OwnID.CoreSDK.AccountManager.State, OwnID.CoreSDK.AccountManager.Action>,
                        oneTimePasswordStore: Store<OwnID.UISDK.OneTimePassword.ViewState, OwnID.UISDK.OneTimePassword.Action>,
                        idCollectViewStore: Store<OwnID.UISDK.IdCollect.ViewState, OwnID.UISDK.IdCollect.Action>)
        case addToStateConfig(config: OwnID.CoreSDK.LocalConfiguration)
        case addToStateShouldStartInitRequest(value: Bool)
        
        case sendInitialRequest
        case initialRequestLoaded(response: InitResponse)
        case idCollect(step: Step)
        case fido2Authorize(step: Step)
        case webApp(step: Step)
        case authManagerRequestFail(error: OwnID.CoreSDK.CoreErrorLogWrapper, browserBaseURL: String)
        case sendStatusRequest
        case authManagerCancelled
        case success
        case oneTimePassword(step: Step)
        case statusRequestLoaded(response: OwnID.CoreSDK.Payload)
        case browserVM(OwnID.CoreSDK.BrowserOpenerViewModel.Action)
        case idCollectView(OwnID.UISDK.IdCollect.Action)
        case oneTimePasswordView(OwnID.UISDK.OneTimePassword.Action)
        case authManager(OwnID.CoreSDK.AccountManager.Action)
        case codeResent
        case stopRequestLoaded(flow: OwnID.CoreSDK.FlowType)
        case sameStep
    }
}
