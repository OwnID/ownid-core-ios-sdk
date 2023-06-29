import Combine

extension OwnID.CoreSDK.CoreViewModel {
    static func reducer(state: inout State, action: Action) -> [Effect<Action>] {
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
        case .idCollect(let step):
            let idCollectStep = IdCollectStep(step: step)
            state.idCollectStep = idCollectStep
            return idCollectStep.run(state: &state)
        case .fido2Authorize(let step):
            let fidoStep = FidoAuthStep(step: step)
            state.fidoStep = fidoStep
            return fidoStep.run(state: &state)
        case .error:
            return []
        case .nonTerminalError:
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
            
        case .oneTimePassword(let step):
            let otpStep = OTPAuthStep(step: step)
            state.otpStep = otpStep
            return otpStep.run(state: &state)
            
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
        case .codeResent:
            return []
            
        case .authManagerRequestFail:
            let stopStep = StopStep()
            return stopStep.run(state: &state)
            
        case .webApp(let step):
            let webAppStep = WebAppStep(step: step)
            return webAppStep.run(state: &state)
            
        case let .addToState(browserViewModelStore, authStore, oneTimePasswordStore, idCollectViewStore):
            state.browserViewModelStore = browserViewModelStore
            state.authManagerStore = authStore
            state.oneTimePasswordStore = oneTimePasswordStore
            state.idCollectViewStore = idCollectViewStore
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
        case let .authManager(authManagerAction):
            switch authManagerAction {
            case .didFinishRegistration(let fido2RegisterPayload, _):
                let fidoStep = state.fidoStep
                return fidoStep?.sendAuthRequest(state: &state, fido2Payload: fido2RegisterPayload, type: .register) ?? []
                
            case .didFinishLogin(let fido2LoginPayload, _):
                let fidoStep = state.fidoStep
                return fidoStep?.sendAuthRequest(state: &state, fido2Payload: fido2LoginPayload, type: .login) ?? []
                
            case .error(let error, _, _):
                let fidoStep = state.fidoStep
                return fidoStep?.handleFidoError(state: &state, error: error) ?? []
            }
            
        case .oneTimePasswordView(let action):
            switch action {
            case .viewLoaded:
                break
            case .resendCode:
                let otpStep = state.otpStep
                return otpStep?.resend(state: &state) ?? []
                
            case .codeEntered(let code):
                let otpStep = state.otpStep
                return otpStep?.sendCode(code: code, state: &state) ?? []

            case .cancel:
                let stopStep = StopStep()
                return stopStep.run(state: &state)
                
            case .emailIsNotRecieved:
                let otpStep = state.otpStep
                return otpStep?.restart(state: &state) ?? []
                
            case .error:
                break
                
            case .success:
                break
                
            case .nonTerminalError:
                break
                
            case .cancelCodeOperation:
                break
                
            case .displayDidNotGetCode:
                break
            case .stopLoading:
                break
            case .codeEnteringStarted:
                break
            }
            return []
            
        case .oneTimePasswordCancelled:
            let stopStep = StopStep()
            return stopStep.run(state: &state)
            
        case .idCollectView(let action):
            switch action {
            case .viewLoaded:
                return []
            case .cancel:
                let stopStep = StopStep()
                return stopStep.run(state: &state)
            case .loginIdEntered(let loginId):
                let idCollectStep = state.idCollectStep
                return idCollectStep?.sendAuthRequest(state: &state, loginId: loginId) ?? []
            case .error:
                return []
            }
        }
    }
}
