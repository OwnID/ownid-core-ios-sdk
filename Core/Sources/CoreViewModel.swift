import Foundation
import Combine
import LocalAuthentication

extension OwnID.CoreSDK {
    final class CoreViewModel: ObservableObject {
        @Published var store: Store<OwnID.CoreSDK.ViewModelState, OwnID.CoreSDK.ViewModelAction>
        private let resultPublisher = PassthroughSubject<OwnID.CoreSDK.Event, OwnID.CoreSDK.CoreErrorLogWrapper>()
        private var bag = Set<AnyCancellable>()
        
        var eventPublisher: OwnID.CoreSDK.EventPublisher { resultPublisher.receive(on: DispatchQueue.main).eraseToAnyPublisher() }
        
        init(type: OwnID.CoreSDK.RequestType,
             email: OwnID.CoreSDK.Email?,
             token: OwnID.CoreSDK.JWTToken?,
             session: APISessionProtocol,
             sdkConfigurationName: String,
             isLoggingEnabled: Bool,
             clientConfiguration: ClientConfiguration?) {
            let initialState = OwnID.CoreSDK.ViewModelState(isLoggingEnabled: isLoggingEnabled,
                                                            clientConfiguration: clientConfiguration,
                                                            sdkConfigurationName: sdkConfigurationName,
                                                            session: session,
                                                            email: email,
                                                            token: token,
                                                            type: type)
            let store = Store(
                initialValue: initialState,
                reducer: with(
                    OwnID.CoreSDK.viewModelReducer,
                    logging
                )
            )
            self.store = store
            let browserStore = self.store.view(value: { $0.sdkConfigurationName } , action: { .browserVM($0) })
            let authManagerStore = self.store.view(value: { AccountManager.State(isLoggingEnabled: $0.isLoggingEnabled) },
                                                   action: { .authManager($0) })
            self.store.send(.addToState(browserViewModelStore: browserStore, authStore: authManagerStore))
            setupEventPublisher()
        }
        
        public func start() {
            if (store.value.clientConfiguration != nil) {
                store.send(.sendInitialRequest)
            } else {
                store.send(.addToStateShouldStartInitRequest(value: true))
                resultPublisher.send(.loading)
            }
        }
        
        public func cancel() {
            if #available(iOS 16.0, *) {
                store.value.authManager?.cancel()
            }
            store.value.browserViewModel?.cancel()
            store.value.browserViewModelStore?.cancel()
            store.send(.cancelled)
        }
        
        func subscribeToURL(publisher: AnyPublisher<Void, OwnID.CoreSDK.CoreErrorLogWrapper>) {
            publisher
                .sink { [unowned self] completion in
                    if case .failure(let error) = completion {
                        store.send(.error(error))
                    }
                } receiveValue: { [unowned self] url in
                    store.send(.sendStatusRequest)
                }
                .store(in: &bag)
        }
        
        func subscribeToConfiguration(publisher: AnyPublisher<ClientConfiguration, Never>) {
            publisher
                .sink { [unowned self] clientConfiguration in
                    self.store.send(.addToStateConfig(clientConfig: clientConfiguration))
                }
                .store(in: &bag)
        }
        
        private var internalStatesChange = [String]()
        
        private func logInternalStates() {
            let logMessage = "\(Self.self): finished ➡️ \(internalStatesChange)"
            OwnID.CoreSDK.logger.logCore(.entry(message: logMessage, Self.self))
            internalStatesChange.removeAll()
        }
        
        private func setupEventPublisher() {
            store
                .actionsPublisher
                .sink { [unowned self] action in
                    switch action {
                    case .sendInitialRequest:
                        internalStatesChange.append(String(describing: action))
                        resultPublisher.send(.loading)
                        
                    case .initialRequestLoaded,
                            .addErrorToInternalStates,
                            .sendStatusRequest,
                            .addToState,
                            .addToStateConfig,
                            .settingsRequestLoaded,
                            .addToStateShouldStartInitRequest,
                            .authManager,
                            .browserVM:
                        internalStatesChange.append(action.debugDescription)
                        
                    case let .authRequestLoaded(payload, shouldPerformStatusRequest):
                        finishIfNeeded(shouldPerformStatusRequest: shouldPerformStatusRequest, payload: payload, action: action)
                        
                    case let .statusRequestLoaded(payload):
                        finishIfNeeded(shouldPerformStatusRequest: false, payload: payload, action: action)
                        
                    case .error(let error):
                        internalStatesChange.append(String(describing: action))
                        flowsFinished()
                        resultPublisher.send(completion: .failure(error))
                        
                    case .browserCancelled,
                            .authManagerCancelled,
                            .cancelled:
                        internalStatesChange.append(String(describing: action))
                        flowsFinished()
                        resultPublisher.send(.cancelled)
                    }
                }
                .store(in: &bag)
        }
        
        private func finishIfNeeded(shouldPerformStatusRequest: Bool, payload: Payload, action: OwnID.CoreSDK.ViewModelAction) {
                internalStatesChange.append(String(describing: action))
                if shouldPerformStatusRequest {
                    return
                }
                flowsFinished()
                resultPublisher.send(.success(payload))
        }
        
        private func flowsFinished() {
            logInternalStates()
            store.cancel()
            bag.removeAll()
        }
    }
}

// MARK: ViewModelAction

extension OwnID.CoreSDK {
    enum ViewModelAction {
        case addToState(browserViewModelStore: Store<BrowserOpenerViewModel.State, BrowserOpenerViewModel.Action>,
                        authStore: Store<AccountManager.State, AccountManager.Action>)
        case addToStateConfig(clientConfig: ClientConfiguration)
        case addToStateShouldStartInitRequest(value: Bool)
        case sendInitialRequest
        case initialRequestLoaded(response: OwnID.CoreSDK.Init.Response)
        case settingsRequestLoaded(response: OwnID.CoreSDK.Setting.Response, origin: String, fido2Payload: Encodable)
        case error(OwnID.CoreSDK.CoreErrorLogWrapper)
        case sendStatusRequest
        case browserCancelled
        case cancelled
        case authManagerCancelled
        case authRequestLoaded(response: OwnID.CoreSDK.Payload, shouldPerformStatusRequest: Bool)
        case statusRequestLoaded(response: OwnID.CoreSDK.Payload)
        case browserVM(BrowserOpenerViewModel.Action)
        case authManager(AccountManager.Action)
        case addErrorToInternalStates(OwnID.CoreSDK.Error)
    }
    
    struct ViewModelState: LoggingEnabled {
        let isLoggingEnabled: Bool
        var clientConfiguration: ClientConfiguration?
        
        let sdkConfigurationName: String
        let session: APISessionProtocol
        let email: OwnID.CoreSDK.Email?
        let token: OwnID.CoreSDK.JWTToken?
        let type: OwnID.CoreSDK.RequestType
        
        var browserViewModelStore: Store<BrowserOpenerViewModel.State, BrowserOpenerViewModel.Action>!
        var browserViewModel: BrowserOpener?
        
        var authManagerStore: Store<AccountManager.State, AccountManager.Action>!
        var authManager: AccountManager?
        
        var shouldStartFlowOnConfigurationReceive = true
    }
    
    static func viewModelReducer(state: inout ViewModelState, action: ViewModelAction) -> [Effect<ViewModelAction>] {
        switch action {
        case .sendInitialRequest:
            if let email = state.email, !email.rawValue.isEmpty, !email.isValid {
                return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .emailIsInvalid))
            }
            return [sendInitialRequest(type: state.type,
                                       token: state.token,
                                       session: state.session,
                                       origin: state.clientConfiguration?.rpId)]
            
        case let .initialRequestLoaded(response):
            guard let context = response.context else { return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .contextIsMissing)) }
            if #available(iOS 16, *),
               let config = state.clientConfiguration,
               let domain = config.rpId,
               config.passkeys {
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
                                         store: state.browserViewModelStore)
                state.browserViewModel = vm
                return []
            }
            
        case let .settingsRequestLoaded(response, origin, fido2RegisterPayload):
            if let challengeType = response.challengeType, challengeType != .register {
                return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .settingRequestResponseNotCompliantResponse))
            }
            return [sendAuthRequest(session: state.session,
                                    origin: origin,
                                    fido2Payload: fido2RegisterPayload,
                                    shouldPerformStatusRequest: false)]
            
        case .error:
            return []
            
        case .sendStatusRequest:
            state.browserViewModel = .none
            return [sendStatusRequest(session: state.session, origin: state.clientConfiguration?.rpId)]
            
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
            
        case let .authRequestLoaded(_ , shouldPerformStatusRequest):
            if shouldPerformStatusRequest {
                return [sendStatusRequest(session: state.session, origin: state.clientConfiguration?.rpId)]
            } else {
                return []
            }
            
        case .statusRequestLoaded:
            return []
            
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
            state.clientConfiguration = clientConfig
            let initialEffect = [Just(OwnID.CoreSDK.ViewModelAction.sendInitialRequest).eraseToEffect()]
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
            case .didFinishRegistration(let origin, let fido2RegisterPayload):
                guard let email = state.email else {
                    return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .emailIsInvalid))
                }
                return [sendSettingsRequest(session: state.session,
                                            loginID: email.rawValue,
                                            origin: origin,
                                            fido2Payload: fido2RegisterPayload)]
                
            case .didFinishLogin(let origin, let fido2LoginPayload):
                /// We intentionally need to perform status request. It is possible to get information from settings request, in our case we
                /// do not have login id that is required for this request.
                return [sendAuthRequest(session: state.session,
                                        origin: origin,
                                        fido2Payload: fido2LoginPayload,
                                        shouldPerformStatusRequest: true)]
                
            case let .error(error, context, browserBaseURL):
                let vm = createBrowserVM(for: context,
                                         browserURL: browserBaseURL,
                                         email: state.email,
                                         sdkConfigurationName: state.sdkConfigurationName,
                                         store: state.browserViewModelStore)
                state.browserViewModel = vm
                return [Just(.addErrorToInternalStates(error)).eraseToEffect()]
            }
        }
    }
    
}

// MARK: Action Functions

extension OwnID.CoreSDK {
    static func createBrowserVM(for context: String,
                                browserURL: String,
                                email: Email?,
                                sdkConfigurationName: String,
                                store: Store<BrowserOpenerViewModel.State, BrowserOpenerViewModel.Action>) -> BrowserOpenerViewModel {
        let redirectionEncoded = OwnID.CoreSDK.shared.getConfiguration(for: sdkConfigurationName)
            .redirectionURL
            .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let redirect = redirectionEncoded! + "?context=" + context
        let redirectParameter = "&redirectURI=" + redirect
        var urlString = browserURL
        if let email {
            var emailSet = CharacterSet.urlHostAllowed
            emailSet.remove("+")
            if let encoded = email.rawValue.addingPercentEncoding(withAllowedCharacters: emailSet) {
                let emailParameter = "&e=" + encoded
                urlString.append(emailParameter)
            }
        }
        urlString.append(redirectParameter)
        let url = URL(string: urlString)!
        let vm = BrowserOpenerViewModel(store: store, url: url)
        return vm
    }
    
    static func errorEffect(_ error: OwnID.CoreSDK.CoreErrorLogWrapper) -> [Effect<ViewModelAction>] {
        [Just(.error(error)).eraseToEffect()]
    }
    
    static func sendInitialRequest(type: OwnID.CoreSDK.RequestType,
                                   token: OwnID.CoreSDK.JWTToken?,
                                   session: APISessionProtocol,
                                   origin: String?) -> Effect<ViewModelAction> {
        session.performInitRequest(type: type, token: token, origin: origin)
            .receive(on: DispatchQueue.main)
            .map { ViewModelAction.initialRequestLoaded(response: $0) }
            .catch { Just(ViewModelAction.error($0)) }
            .eraseToEffect()
    }
    
    static func sendSettingsRequest(session: APISessionProtocol, loginID: String, origin: String, fido2Payload: Encodable) -> Effect<ViewModelAction> {
        session.performSettingsRequest(loginID: loginID, origin: origin)
            .receive(on: DispatchQueue.main)
            .map { ViewModelAction.settingsRequestLoaded(response: $0, origin: origin, fido2Payload: fido2Payload) }
            .catch { Just(ViewModelAction.error($0)) }
            .eraseToEffect()
    }
    
    static func sendAuthRequest(session: APISessionProtocol,
                                origin: String,
                                fido2Payload: Encodable,
                                shouldPerformStatusRequest: Bool) -> Effect<ViewModelAction> {
        session.performAuthRequest(origin: origin, fido2Payload: fido2Payload, shouldIgnoreResponseBody: shouldPerformStatusRequest)
            .receive(on: DispatchQueue.main)
            .map { ViewModelAction.authRequestLoaded(response: $0, shouldPerformStatusRequest: shouldPerformStatusRequest) }
            .catch { Just(ViewModelAction.error($0)) }
            .eraseToEffect()
    }
    
    static func sendStatusRequest(session: APISessionProtocol, origin: String?) -> Effect<ViewModelAction> {
        session.performStatusRequest(origin: origin)
            .map { ViewModelAction.statusRequestLoaded(response: $0) }
            .catch { Just(ViewModelAction.error($0)) }
            .eraseToEffect()
    }
}
