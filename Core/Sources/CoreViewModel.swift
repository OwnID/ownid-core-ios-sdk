import Foundation
import Combine
import LocalAuthentication

extension OwnID.CoreSDK.ViewModelAction: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .addToState:
            return "addToState"
        case .sendInitialRequest:
            return "sendInitialRequest"
        case .initialRequestLoaded:
            return "initialRequestLoaded"
        case .browserURLCreated:
            return "browserURLCreated"
        case .error(let error):
            return "error \(error.localizedDescription)"
        case .sendStatusRequest:
            return "sendStatusRequest"
        case .browserCancelled:
            return "browserCancelled"
        case .statusRequestLoaded:
            return "statusRequestLoaded"
        case .browserVM:
            return "browserVM"
        case .authRequestLoaded:
            return "authRequestLoaded"
        case .authManager(let action):
            return "authManagerAction \(action.debugDescription)"
        case .authManagerCancelled:
            return "authManagerCancelled"
        }
    }
}

extension OwnID.CoreSDK {
    enum ViewModelAction {
        case addToState(browserViewModelStore: Store<BrowserOpenerViewModel.State, BrowserOpenerViewModel.Action>,
                        authStore: Store<AccountManager.State, AccountManager.Action>)
        case sendInitialRequest
        case initialRequestLoaded(response: OwnID.CoreSDK.Init.Response)
        case authRequestLoaded(response: OwnID.CoreSDK.Auth.Response)
        case browserURLCreated(URL)
        case error(OwnID.CoreSDK.Error)
        case sendStatusRequest
        case browserCancelled
        case authManagerCancelled
        case statusRequestLoaded(response: OwnID.CoreSDK.Payload)
        case browserVM(BrowserOpenerViewModel.Action)
        case authManager(AccountManager.Action)
    }
    
    struct ViewModelState: LoggingEnabled {
        let isLoggingEnabled: Bool
        let clientConfiguration: ClientConfiguration?
        
        let sdkConfigurationName: String
        let session: APISessionProtocol
        let email: OwnID.CoreSDK.Email?
        let token: OwnID.CoreSDK.JWTToken?
        let type: OwnID.CoreSDK.RequestType
        
        var browserViewModelStore: Store<BrowserOpenerViewModel.State, BrowserOpenerViewModel.Action>!
        var browserViewModel: BrowserOpener?
        
        var authManagerStore: Store<AccountManager.State, AccountManager.Action>!
        var authManager: AccountManager?
    }
    
    static func viewModelReducer(state: inout ViewModelState, action: ViewModelAction) -> [Effect<ViewModelAction>] {
        switch action {
        case .sendInitialRequest:
            if let email = state.email, !email.rawValue.isEmpty, !email.isValid {
                return errorEffect(.emailIsInvalid)
            }
            return [sendInitialRequest(type: state.type,
                                       token: state.token,
                                       session: state.session,
                                       origin: state.clientConfiguration?.rpId)]
            
        case let .initialRequestLoaded(response):
            guard let context = response.context else { return errorEffect(.contextIsMissing) }
            var passkeysPossibilityAvailable = false
            
            /// Passkeys available only for > iOS 16
            if #available(iOS 16, *) {
                let authContext = LAContext()
                authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
                passkeysPossibilityAvailable = authContext.biometryType != .none
            }
            #warning("hardcoded values")
            let config: ClientConfiguration? = .init(logLevel: 1, passkeys: true, rpId: "passwordless.staging.ownid.com", passkeysAutofill: false)
            if passkeysPossibilityAvailable,
               #available(iOS 16, *),
               let config = state.clientConfiguration,
               let domain = config.rpId,
               config.passkeys {
                let authManager = OwnID.CoreSDK.AccountManager(store: state.authManagerStore,
                                                               domain: domain,
                                                               challenge: state.session.context)
                switch state.type {
                case .register:
                    authManager.signUpWith(userName: state.email?.rawValue ?? "")
                    
                case .login:
                    authManager.signInWith(preferImmediatelyAvailableCredentials: true)
                }
                state.authManager = authManager
                return []
            } else {
                let browserAffect = browserURLEffect(for: context,
                                                     browserURL: response.url,
                                                     email: state.email,
                                                     sdkConfigurationName: state.sdkConfigurationName)
                return [browserAffect]
            }
            
        case .authRequestLoaded:
            return [sendStatusRequest(session: state.session, origin: state.clientConfiguration?.rpId)]
            
        case .error:
            return []
            
        case let .browserURLCreated(url):
            let vm = BrowserOpenerViewModel(store: state.browserViewModelStore, url: url)
            state.browserViewModel = vm
            return []
            
        case .sendStatusRequest:
            state.browserViewModel = .none
            return [sendStatusRequest(session: state.session, origin: state.clientConfiguration?.rpId)]
            
        case .browserCancelled:
            state.browserViewModel = .none
            return []
            
        case .authManagerCancelled:
            state.authManager = .none
            return []
            
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
            
        case let .authManager(authManagerAction):
            switch authManagerAction {
            case .didFinishRegistration(let origin, let fido2RegisterPayload):
                return [sendAuthRequest(session: state.session, origin: origin, fido2Payload: fido2RegisterPayload)]
                
            case .didFinishLogin(let origin, let fido2LoginPayload):
                return [sendAuthRequest(session: state.session, origin: origin, fido2Payload: fido2LoginPayload)]
                
            case .credintialsNotFoundOrCanlelledByUser:
                return [Just(.authManagerCancelled).eraseToEffect()]
                
            case .error(let error):
                return [Just(.error(error)).eraseToEffect()]
            }
        }
    }
    
    static func browserURLEffect(for context: String,
                                 browserURL: String,
                                 email: Email?,
                                 sdkConfigurationName: String) -> Effect<ViewModelAction> {
        Effect<ViewModelAction>.sync {
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
            return .browserURLCreated(URL(string: urlString)!)
        }
    }
    
    static func errorEffect(_ error: OwnID.CoreSDK.Error) -> [Effect<ViewModelAction>] {
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
    
    static func sendAuthRequest(session: APISessionProtocol, origin: String, fido2Payload: Encodable) -> Effect<ViewModelAction> {
        session.performAuthRequest(origin: origin, fido2Payload: fido2Payload)
            .receive(on: DispatchQueue.main)
            .map { ViewModelAction.authRequestLoaded(response: $0) }
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

extension OwnID.CoreSDK {
    public final class CoreViewModel: ObservableObject {
        @Published var store: Store<OwnID.CoreSDK.ViewModelState, OwnID.CoreSDK.ViewModelAction>
        private let resultPublisher = PassthroughSubject<OwnID.CoreSDK.Event, OwnID.CoreSDK.Error>()
        private var bag = Set<AnyCancellable>()
        
        public var eventPublisher: OwnID.CoreSDK.EventPublisher { resultPublisher.receive(on: DispatchQueue.main).eraseToAnyPublisher() }
        
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
            store.send(.sendInitialRequest)
        }
        
        func subscribeToURL(publisher: AnyPublisher<Void, OwnID.CoreSDK.Error>) {
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
        
        private var internalStatesChange = [String]()
        
        private func logInternalStates() {
            let logMessage = "\(internalStatesChange)"
            if store.value.isLoggingEnabled {
                print("\(Self.self): \(#function) ➡️ \(logMessage)")
            }
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
                            .browserURLCreated,
                            .sendStatusRequest,
                            .addToState,
                            .authRequestLoaded,
                            .authManager,
                            .browserVM:
                        internalStatesChange.append(String(describing: action))
                        
                    case let .statusRequestLoaded(payload):
                        internalStatesChange.append(String(describing: action))
                        flowsFinished()
                        resultPublisher.send(.success(payload))
                        
                    case .error(let error):
                        internalStatesChange.append(String(describing: action))
                        flowsFinished()
                        resultPublisher.send(completion: .failure(error))
                        
                    case .browserCancelled,
                            .authManagerCancelled:
                        internalStatesChange.append(String(describing: action))
                        flowsFinished()
                        resultPublisher.send(.cancelled)
                    }
                }
                .store(in: &bag)
        }
        
        private func flowsFinished() {
            logInternalStates()
            bag.removeAll()
        }
    }
}
