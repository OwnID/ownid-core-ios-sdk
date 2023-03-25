import Combine

extension OwnID.CoreSDK.CoreViewModel {
    static func reducer(state: inout State, action: Action) -> [Effect<Action>] {
        switch action {
        case .sendInitialRequest:
            let emailInvalidEffect = errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .emailIsInvalid))
            if state.email == nil {
                return emailInvalidEffect
            }
            if let email = state.email, !email.rawValue.isEmpty, !email.isValid {
                return emailInvalidEffect
            }
            guard let configuration = state.configuration else { return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .localConfigIsNotPresent)) }
            let session = OwnID.CoreSDK.APISession(initURL: configuration.initURL,
                                                   statusURL: configuration.statusURL,
                                                   finalStatusURL: configuration.finalStatusURL,
                                                   authURL: configuration.authURL,
                                                   supportedLanguages: state.supportedLanguages)
            state.session = session
            return [sendInitialRequest(requestData: OwnID.CoreSDK.Init.RequestData(loginId: state.email?.rawValue,
                                                                                   type: state.type,
                                                                                   supportsFido2: isPasskeysSupported),
                                       session: session)]
            
        case let .initialRequestLoaded(response):
            guard let context = response.context else { return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .contextIsMissing)) }
            if #available(iOS 16, *),
               let config = state.configuration,
               let domain = config.fidoSettings?.rpID {
                let authManager = OwnID.CoreSDK.AccountManager(store: state.authManagerStore,
                                                               domain: domain,
                                                               challenge: state.session.context,
                                                               browserBaseURL: response.url)
                switch state.type {
                case .register:
                    authManager.signUpWith(userName: state.email?.rawValue ?? "")
                    
                case .login:
                    authManager.signInWith()
                }
                state.authManager = authManager
                return []
            } else {
                let vm = createBrowserVM(for: context,
                                         browserURL: response.url,
                                         email: state.email,
                                         sdkConfigurationName: state.sdkConfigurationName,
                                         store: state.browserViewModelStore,
                                         redirectionURLString: state.configuration?.redirectionURL)
                state.browserViewModel = vm
                return []
            }
            
        case .error:
            return []
            
        case .sendStatusRequest:
            state.browserViewModel = .none
            return [sendStatusRequest(session: state.session)]
            
        case .browserCancelled:
            state.browserViewModel = .none
            return []
            
        case .cancelled:
            state.browserViewModel = .none
            state.authManager = .none
            return []
            
        case .authManagerCancelled:
            state.authManager = .none
            return []
            
        case .authRequestLoaded:
            return [sendStatusRequest(session: state.session)]
            
        case .statusRequestLoaded:
            return []
            
        case .authManagerRequestFail(let error, let browserBaseURL):
            let vm = createBrowserVM(for: state.session.context,
                                     browserURL: browserBaseURL,
                                     email: state.email,
                                     sdkConfigurationName: state.sdkConfigurationName,
                                     store: state.browserViewModelStore,
                                     redirectionURLString: state.configuration?.redirectionURL)
            state.browserViewModel = vm
            return [Just(.addErrorToInternalStates(error.error)).eraseToEffect()]
            
        case let .addToState(browserViewModelStore, authStore):
            state.browserViewModelStore = browserViewModelStore
            state.authManagerStore = authStore
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
            case .didFinishRegistration(let fido2RegisterPayload, let browserBaseURL):
                return didFinishAuthManagerAction(state, fido2RegisterPayload, browserBaseURL)
                
            case .didFinishLogin(let fido2LoginPayload, let browserBaseURL):
                return didFinishAuthManagerAction(state, fido2LoginPayload, browserBaseURL)
                
            case let .error(error, context, browserBaseURL):
                let vm = createBrowserVM(for: context,
                                         browserURL: browserBaseURL,
                                         email: state.email,
                                         sdkConfigurationName: state.sdkConfigurationName,
                                         store: state.browserViewModelStore,
                                         redirectionURLString: state.configuration?.redirectionURL)
                state.browserViewModel = vm
                return [Just(.addErrorToInternalStates(error)).eraseToEffect()]
            }
        }
    }
}