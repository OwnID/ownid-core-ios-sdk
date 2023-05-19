import Combine

extension OwnID.CoreSDK.CoreViewModel {
    static func reducer(state: inout State, action: Action) -> [Effect<Action>] {
        //TODO: remove it
        let loginIdSettings = state.configuration?.loginIdSettings ?? OwnID.CoreSDK.LoginIdSettings(type: .email, regex: "")
        let loginId = OwnID.CoreSDK.LoginId(value: state.loginId, settings: loginIdSettings)
        
        switch action {
        case .sendInitialRequest:
            let step = InitStep()
            let effect = step.run(state: &state)
            return effect
        case let .initialRequestLoaded(response):
            state.stopUrl = URL(string: response.stopUrl)
            state.finalUrl = URL(string: response.finalStatusUrl)
            state.context = response.context
            
            let baseStep = BaseStep()
            let action = baseStep.nextStepAction(response.step)
            
            return [Just(action).eraseToEffect()]
        case .idCollect:
//            OwnID.UISDK.showInstantConnectView(viewModel: <#T##OwnID.FlowsSDK.LoginView.ViewModel#>, visualConfig: <#T##OwnID.UISDK.VisualLookConfig#>)
            return []
        case .fido2Authorize(let step):
            let fidoStep = FidoAuthStep(step: step)
            state.fidoStep = fidoStep
            return fidoStep.run(state: &state)
        case .error:
            return []
            
        case .sendStatusRequest:
            state.browserViewModel = .none
            let finalStep = FinalStep()
            return finalStep.run(state: &state)
            
        case .browserCancelled:
            state.browserViewModel = .none
            let stopStep = StopStep()
            return stopStep.run(state: &state)
            
        case .cancelled:
            state.browserViewModel = .none
            state.authManager = .none
            return []
            //TODO: cancel request if all other cancels lead here
            
        case .oneTimePassword:
            OwnID.UISDK.showOTPView(store: state.oneTimePasswordStore)
            return []
            
        case .authManagerCancelled:
            state.authManager = .none
            return []
            
        case .success:
            let finalStep = FinalStep()
            return finalStep.run(state: &state)
            
        case .statusRequestLoaded:
            return []
        case .stopRequestLoaded:
            return []
            
        case .authManagerRequestFail(let error, let browserBaseURL):
            let vm = createBrowserVM(for: state.context,
                                     browserURL: browserBaseURL,
                                     loginId: loginId,
                                     sdkConfigurationName: state.sdkConfigurationName,
                                     store: state.browserViewModelStore,
                                     redirectionURLString: state.configuration?.redirectionURL,
                                     creationClosure: state.createBrowserOpenerClosure)
            state.browserViewModel = vm
            return [Just(.addErrorToInternalStates(error.error)).eraseToEffect()]
            
        case let .addToState(browserViewModelStore, authStore, oneTimePasswordStore):
            state.browserViewModelStore = browserViewModelStore
            state.authManagerStore = authStore
            state.oneTimePasswordStore = oneTimePasswordStore
            return []
            
        case let .browserVM(browserVMAction):
            switch browserVMAction {
            case .viewCancelled:
                return [Just(.browserCancelled).eraseToEffect()]
            }
            
        case let .addToStateConfig(clientConfig):
            state.configuration = clientConfig
            let initialEffect = [Just(Action.sendInitialRequest).eraseToEffect()]
            let effect = state.shouldStartFlowOnConfigurationReceive ? initialEffect : []
            return effect + [Just(.addToStateShouldStartInitRequest(value: false)).eraseToEffect()]
            
        case let .addToStateShouldStartInitRequest(value):
            state.shouldStartFlowOnConfigurationReceive = value
            return []
            
        case .addErrorToInternalStates:
            return []
            
        // MARK: AuthManager
            //TODO: move auth manager action handling to fido step
        case let .authManager(authManagerAction):
            switch authManagerAction {
            case .didFinishRegistration(let fido2RegisterPayload, let browserBaseURL):
                let fidoStep = state.fidoStep
                return fidoStep?.sendAuthRequest(state: &state, fido2Payload: fido2RegisterPayload) ?? []
                
            case .didFinishLogin(let fido2LoginPayload, let browserBaseURL):
                let fidoStep = state.fidoStep
                return fidoStep?.sendAuthRequest(state: &state, fido2Payload: fido2LoginPayload) ?? []
                
            case let .error(error, context, browserBaseURL):
                let vm = createBrowserVM(for: context,
                                         browserURL: browserBaseURL,
                                         loginId: loginId,
                                         sdkConfigurationName: state.sdkConfigurationName,
                                         store: state.browserViewModelStore,
                                         redirectionURLString: state.configuration?.redirectionURL,
                                         creationClosure: state.createBrowserOpenerClosure)
                state.browserViewModel = vm
                return [Just(.addErrorToInternalStates(error)).eraseToEffect()]
            }
            
        case .oneTimePasswordView(let action):
            switch action {
            case .codeEntered(let code):
                break
                
            case .cancel:
                return [Just(.oneTimePasswordCancelled).eraseToEffect()]
                
            case .emailIsNotRecieved:
                break
                
            case .error:
                break
                
            case .cancelCodeOperation:
                break
                
            case .displayDidNotGetCode:
                break
            case .stopLoading:
                break
            }
            return []
            
        case .oneTimePasswordCancelled:
            return []
        }
    }
}
