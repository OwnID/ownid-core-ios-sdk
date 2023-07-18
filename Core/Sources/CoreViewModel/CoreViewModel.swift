import Foundation
import Combine

extension OwnID.CoreSDK {
    final class CoreViewModel: ObservableObject {
        @Published var store: Store<State, Action>
        private let resultPublisher = PassthroughSubject<Event, OwnID.CoreSDK.CoreErrorLogWrapper>()
        private var bag = Set<AnyCancellable>()
        
        var eventPublisher: EventPublisher { resultPublisher.receive(on: DispatchQueue.main).eraseToAnyPublisher() }
        
        init(type: OwnID.CoreSDK.RequestType,
             loginId: String,
             supportedLanguages: OwnID.CoreSDK.Languages,
             sdkConfigurationName: String,
             isLoggingEnabled: Bool,
             clientConfiguration: LocalConfiguration?,
             createAccountManagerClosure: @escaping AccountManager.CreationClosure = OwnID.CoreSDK.AccountManager.defaultAccountManager,
             createBrowserOpenerClosure: @escaping BrowserOpener.CreationClosure = BrowserOpener.defaultOpener) {
            var loginId = loginId
            if loginId.isBlank, let savedLoginId = DefaultsLoginIdSaver.getLoginId(), !savedLoginId.isBlank, type == .login {
                loginId = savedLoginId
            }
            let initialState = State(isLoggingEnabled: isLoggingEnabled,
                                     configuration: clientConfiguration,
                                     createAccountManagerClosure: createAccountManagerClosure,
                                     createBrowserOpenerClosure: createBrowserOpenerClosure,
                                     sdkConfigurationName: sdkConfigurationName,
                                     loginId: loginId,
                                     type: type,
                                     supportedLanguages: supportedLanguages)
            let store = Store(
                initialValue: initialState,
                reducer: with(
                    Self.reducer,
                    logging
                )
            )
            self.store = store
            
            let idCollectViewStore = self.store.view(
                value: { OwnID.UISDK.IdCollect.ViewState(isLoggingEnabled: $0.isLoggingEnabled) },
                action: { .idCollectView($0) },
                action: { globalAction in
                    switch globalAction {
                    case .error(let wrapper):
                        let error = wrapper.error
                        switch error {
                        case .userError(let errorModel):
                            return .error(errorModel, flowFinished: wrapper.flowFinished)
                        default:
                            return .error(OwnID.CoreSDK.UserErrorModel(message: ""), flowFinished: wrapper.flowFinished)
                        }
                    default:
                        break
                    }
                    return nil
                },
                reducer: { OwnID.UISDK.IdCollect.viewModelReducer(state: &$0, action: $1) }
            )
            let oneTimePasswordViewStore = self.store.view(
                value: { OwnID.UISDK.OneTimePassword.ViewState(isLoggingEnabled: $0.isLoggingEnabled, type: $0.type) },
                action: { .oneTimePasswordView($0) },
                action: { globalAction in
                    switch globalAction {
                    case .error(let wrapper):
                        let error = wrapper.error
                        switch error {
                        case .userError(let errorModel):
                            return .error(errorModel, flowFinished: wrapper.flowFinished)
                        default:
                            return .error(OwnID.CoreSDK.UserErrorModel(message: ""), flowFinished: wrapper.flowFinished)
                        }
                    case .success:
                        return .success
                    default:
                        break
                    }
                    return .none
                },
                reducer: { OwnID.UISDK.OneTimePassword.viewModelReducer(state: &$0, action: $1) }
            )
            let browserStore = self.store.view(value: { $0.sdkConfigurationName } , action: { .browserVM($0) })
            let authManagerStore = self.store.view(value: { AccountManager.State(isLoggingEnabled: $0.isLoggingEnabled) },
                                                   action: { .authManager($0) })
            self.store.send(.addToState(browserViewModelStore: browserStore,
                                        authStore: authManagerStore,
                                        oneTimePasswordStore: oneTimePasswordViewStore,
                                        idCollectViewStore: idCollectViewStore))
            setupEventPublisher()
        }
        
        public func start() {
            if (store.value.configuration != nil) {
                store.send(.sendInitialRequest)
            } else {
                OwnID.CoreSDK.shared.requestConfiguration()
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
        
        func subscribeToConfiguration(publisher: AnyPublisher<ConfigurationLoadingEvent, Never>) {
            publisher
                .sink { [unowned self] event in
                    switch event {
                        
                    case .loaded(let configuration):
                        store.send(.addToStateConfig(config: configuration))
                        
                    case .error(let error):
                        store.send(.error(.coreLog(error: error, type: Self.self)))
                    }
                }
                .store(in: &bag)
        }
        
        private var internalStatesChange = [String]()
        
        private func logInternalStates() {
            let states = internalStatesLog(states: internalStatesChange)
            OwnID.CoreSDK.logger.log(level: .debug, message: states, Self.self)
            internalStatesChange.removeAll()
        }
        
        private func internalStatesLog(states: [String]) -> String {
            "\(Self.self): finished states ➡️ \(internalStatesChange)"
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
                            .idCollect,
                            .fido2Authorize,
                            .addErrorToInternalStates,
                            .sendStatusRequest,
                            .authManagerRequestFail,
                            .addToState,
                            .addToStateConfig,
                            .addToStateShouldStartInitRequest,
                            .idCollectView,
                            .authManager,
                            .oneTimePasswordView,
                            .oneTimePassword,
                            .browserVM,
                            .webApp,
                            .success,
                            .codeResent,
                            .authManagerCancelled,
                            .cancelled,
                            .sameStep:
                        internalStatesChange.append(action.debugDescription)
                        
                    case let .statusRequestLoaded(payload):
                        internalStatesChange.append(String(describing: action))
                        finishIfNeeded(payload: payload)
                        
                    case .error(let error):
                        internalStatesChange.append(String(describing: action))
                        if !error.isOnUI {
                            flowsFinished()
                            resultPublisher.send(completion: .failure(error))
                        }
                    case .stopRequestLoaded(let flow):
                        internalStatesChange.append(String(describing: action))
                        flowsFinished()
                        resultPublisher.send(.cancelled(flow: flow))
                    }
                }
                .store(in: &bag)
        }
        
        private func finishIfNeeded(payload: Payload) {
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
