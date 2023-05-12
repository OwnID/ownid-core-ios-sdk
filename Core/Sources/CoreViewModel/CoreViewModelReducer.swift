import Combine

extension OwnID.CoreSDK.CoreViewModel {
    static func reducer(state: inout State, action: Action) -> [Effect<Action>] {
        //TODO: get rid of this default LoginIdSettings
        let loginIdSettings = state.configuration?.loginIdSettings ?? OwnID.CoreSDK.LoginIdSettings(type: .email, regex: "")
        let loginId = OwnID.CoreSDK.LoginId(value: state.loginId, settings: loginIdSettings)
        
        switch action {
        case .sendInitialRequest:
            
            guard loginId.isValid else {
                return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: loginId.error))
            }
            
            guard let configuration = state.configuration else { return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .localConfigIsNotPresent)) }
            let session = state.apiSessionCreationClosure(configuration.initURL,
                                                          configuration.statusURL,
                                                          configuration.finalStatusURL,
                                                          configuration.authURL,
                                                          state.supportedLanguages)
            state.session = session
            return [sendInitialRequest(requestData: OwnID.CoreSDK.Init.RequestData(loginId: loginId.value,
                                                                                   type: state.type,
                                                                                   supportsFido2: isPasskeysSupported),
                                       session: session)]
            
        case let .initialRequestLoaded(response):
            guard let context = response.context else { return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .contextIsMissing)) }
            if #available(iOS 16, *),
               let config = state.configuration,
               let domain = config.fidoSettings?.rpID {
                 let authManager = state.createAccountManagerClosure(state.authManagerStore, domain, state.session.context, response.url)
                switch state.type {
                case .register:
                    authManager.signUpWith(userName: loginId.value)
                    
                case .login:
                    authManager.signInWith()
                }
                state.authManager = authManager
                return []
            } else {
                let vm = createBrowserVM(for: context,
                                         browserURL: response.url,
                                         loginId: loginId,
                                         sdkConfigurationName: state.sdkConfigurationName,
                                         store: state.browserViewModelStore,
                                         redirectionURLString: state.configuration?.redirectionURL,
                                         creationClosure: state.createBrowserOpenerClosure)
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
            
        case .oneTimePassword:
            OwnID.UISDK.showOTPView(store: state.oneTimePasswordStore)
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
        case let .authManager(authManagerAction):
            switch authManagerAction {
            case .didFinishRegistration(let fido2RegisterPayload, let browserBaseURL):
                return didFinishAuthManagerAction(state, fido2RegisterPayload, browserBaseURL)
                
            case .didFinishLogin(let fido2LoginPayload, let browserBaseURL):
                return didFinishAuthManagerAction(state, fido2LoginPayload, browserBaseURL)
                
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
            }
            return []
            
        case .oneTimePasswordCancelled:
            return []
        }
    }
}
