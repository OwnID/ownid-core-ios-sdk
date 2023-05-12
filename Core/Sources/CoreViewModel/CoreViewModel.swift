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
             apiSessionCreationClosure: @escaping APISessionProtocol.CreationClosure = OwnID.CoreSDK.APISession.defaultAPISession,
             createAccountManagerClosure: @escaping AccountManager.CreationClosure = OwnID.CoreSDK.AccountManager.defaultAccountManager,
             createBrowserOpenerClosure: @escaping BrowserOpener.CreationClosure = BrowserOpener.defaultOpener) {
            let initialState = State(isLoggingEnabled: isLoggingEnabled,
                                     configuration: clientConfiguration,
                                     apiSessionCreationClosure: apiSessionCreationClosure,
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
            let oneTimePasswordViewStore = self.store.view(
                value: { OwnID.UISDK.OneTimePasswordView.ViewState(isLoggingEnabled: $0.isLoggingEnabled) },
                action: { .oneTimePasswordView($0) },
                action: { globalAction in
                    switch globalAction {
                    case .error(let error):
                        return .error(error.error.localizedDescription)
                        
                    default:
                        break
                    }
                    return .none
                },
                reducer: {
                    if #available(iOS 15.0, *) {
                        return OwnID.UISDK.OneTimePasswordView.viewModelReducer(state: &$0, action: $1)
                    } else {
                        return []
                    }
                }
            )
            let browserStore = self.store.view(value: { $0.sdkConfigurationName } , action: { .browserVM($0) })
            let authManagerStore = self.store.view(value: { AccountManager.State(isLoggingEnabled: $0.isLoggingEnabled) },
                                                   action: { .authManager($0) })
            self.store.send(.addToState(browserViewModelStore: browserStore, authStore: authManagerStore, oneTimePasswordStore: oneTimePasswordViewStore))
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
                        
                    case .error:
                        store.send(.error(.coreLog(entry: .errorEntry(Self.self), error: .localConfigIsNotPresent)))
                    }
                }
                .store(in: &bag)
        }
        
        private var internalStatesChange = [String]()
        
        private func logInternalStates() {
            let states = internalStatesLog(states: internalStatesChange)
            OwnID.CoreSDK.logger.logCore(.entry(message: states, Self.self))
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
                            .addErrorToInternalStates,
                            .sendStatusRequest,
                            .authManagerRequestFail,
                            .addToState,
                            .addToStateConfig,
                            .addToStateShouldStartInitRequest,
                            .authManager,
                            .oneTimePasswordView,
                            .oneTimePassword,
                            .browserVM,
                            .authRequestLoaded:
                        internalStatesChange.append(action.debugDescription)
                        
                    case let .statusRequestLoaded(payload):
                        internalStatesChange.append(String(describing: action))
                        finishIfNeeded(payload: payload)
                        
                    case .error(let error):
                        internalStatesChange.append(String(describing: action))
                        error.entry.message += " " + internalStatesLog(states: internalStatesChange)
                        flowsFinished()
                        resultPublisher.send(completion: .failure(error))
                        
                    case .browserCancelled,
                            .authManagerCancelled,
                            .oneTimePasswordCancelled,
                            .cancelled:
                        internalStatesChange.append(String(describing: action))
                        flowsFinished()
                        resultPublisher.send(.cancelled)
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
