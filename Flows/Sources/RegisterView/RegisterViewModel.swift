import Foundation
import Combine

extension OwnID.FlowsSDK.RegisterView.ViewModel {
    enum State {
        case initial
        case coreVM
        case ownidCreated
    }
}

extension OwnID.FlowsSDK.RegisterView.ViewModel.State {
    var buttonState: OwnID.UISDK.ButtonState {
        switch self {
        case .initial, .coreVM:
            return .enabled
            
        case .ownidCreated:
            return .activated
        }
    }
    
    var isLoading: Bool {
        switch self {
        case .initial, .ownidCreated:
            return false
            
        case .coreVM:
            return true
        }
    }
}

extension OwnID.FlowsSDK.RegisterView.ViewModel {
    public struct EmptyRegisterParameters: RegisterParameters {
        public init () { }
    }
    
    struct RegistrationData {
        fileprivate var payload: OwnID.CoreSDK.Payload?
        fileprivate var persistedEmail = OwnID.CoreSDK.Email(rawValue: "")
    }
}

public extension OwnID.FlowsSDK.RegisterView {
    final class ViewModel: ObservableObject {
        @Published private(set) var state = State.initial
        @Published public var shouldShowTooltip = false
        
        /// Checks email if it is valid for tooltip display. On each change of email,
        /// this closure determines if tooltop should be shown. To change this behaviour,
        /// provide your closure. To disable, provide empty closure:
        /// `{ _ in false }`
        public var shouldShowTooltipEmailProcessingClosure: ((String?) -> Bool) = { emailString in
            guard let emailString else { return false }
            let emailObject = OwnID.CoreSDK.Email(rawValue: emailString)
            return emailObject.isValid
        }
        
        private var bag = Set<AnyCancellable>()
        private var coreViewModelBag = Set<AnyCancellable>()
        private let resultPublisher = PassthroughSubject<Result<OwnID.FlowsSDK.RegistrationEvent, OwnID.CoreSDK.Error>, Never>()
        private let registrationPerformer: RegistrationPerformer
        private var registrationData = RegistrationData()
        private let loginPerformer: LoginPerformer
        private var email = ""
        var coreViewModel: OwnID.CoreSDK.CoreViewModel!
        var currentMetadata: OwnID.CoreSDK.MetricLogEntry.CurrentMetricInformation?
        
        let sdkConfigurationName: String
        
        public var eventPublisher: OwnID.RegistrationPublisher {
            resultPublisher.eraseToAnyPublisher()
        }
        
        public init(registrationPerformer: RegistrationPerformer,
                    loginPerformer: LoginPerformer,
                    sdkConfigurationName: String,
                    emailPublisher: OwnID.CoreSDK.EmailPublisher) {
            self.sdkConfigurationName = sdkConfigurationName
            self.registrationPerformer = registrationPerformer
            self.loginPerformer = loginPerformer
            emailPublisher.assign(to: \.email, on: self).store(in: &bag)
            emailPublisher
                .removeDuplicates()
                .debounce(for: .seconds(0.77), scheduler: DispatchQueue.main)
                .sink { [unowned self] userEmail in
                shouldShowTooltip = shouldShowTooltipEmailProcessingClosure(userEmail)
            }
            .store(in: &bag)
            Task {
                // Delay the task by 1 second
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                sendMetric()
            }
        }
        
        private func sendMetric() {
            if let currentMetadata {
                OwnID.CoreSDK.shared.currentMetricInformation = currentMetadata
            }
            OwnID.CoreSDK.logger.logAnalytic(.registerTrackMetric(action: .loaded, context: registrationData.payload?.context))
        }
        
        public func register(registerParameters: RegisterParameters = EmptyRegisterParameters()) {
            if email.isEmpty {
                handle(.coreLog(entry: .errorEntry(context: registrationData.payload?.context, Self.self), error: .plugin(underlying: OwnID.FlowsSDK.RegisterError.emailIsMissing)))
                return
            }
            guard let payload = registrationData.payload else {
                handle(.coreLog(entry: .errorEntry(context: registrationData.payload?.context, Self.self), error: .payloadMissing(underlying: .none)))
                return
            }
            let config = OwnID.FlowsSDK.RegistrationConfiguration(payload: payload,
                                                                  email: OwnID.CoreSDK.Email(rawValue: email))
            registrationPerformer.register(configuration: config, parameters: registerParameters)
                .sink { [unowned self] completion in
                    if case .failure(let error) = completion {
                        handle(error)
                    }
                } receiveValue: { [unowned self] registrationResult in
                    OwnID.CoreSDK.logger.logAnalytic(.registerTrackMetric(action: .registered,
                                                                          context: payload.context,
                                                                          authType: registrationResult.authType))
                    OwnID.CoreSDK.DefaultsEmailSaver.save(email: email)
                    resultPublisher.send(.success(.userRegisteredAndLoggedIn(registrationResult: registrationResult.operationResult, authType: registrationResult.authType)))
                    resetDataAndState()
                }
                .store(in: &bag)
        }
        
        /// Reset visual state and any possible data from web flow
        public func resetDataAndState(isResettingToInitialState: Bool = true) {
            registrationData = RegistrationData()
            resetToInitialState(isResettingToInitialState: isResettingToInitialState)
        }
        
        /// Reset visual state
        public func resetToInitialState(isResettingToInitialState: Bool = true) {
            if isResettingToInitialState {
                state = .initial
            }
            coreViewModel?.cancel()
            coreViewModelBag.forEach { $0.cancel() }
            coreViewModelBag.removeAll()
            coreViewModel = .none
        }
        
        func skipPasswordTapped(usersEmail: String) {
            if case .coreVM = state {
                resetToInitialState()
                return
            }
            if case .ownidCreated = state {
                OwnID.CoreSDK.logger.logAnalytic(.registerClickMetric(action: .undo, context: registrationData.payload?.context))
                resetToInitialState()
                resultPublisher.send(.success(.resetTapped))
                return
            }
            if registrationData.payload != nil {
                state = .ownidCreated
                resultPublisher.send(.success(.readyToRegister(usersEmailFromWebApp: usersEmail, authType: registrationData.payload?.authType)))
                return
            }
            let email = OwnID.CoreSDK.Email(rawValue: usersEmail)
            let coreViewModel = OwnID.CoreSDK.shared.createCoreViewModelForRegister(email: email, sdkConfigurationName: sdkConfigurationName)
            self.coreViewModel = coreViewModel
            subscribe(to: coreViewModel.eventPublisher, persistingEmail: email)
            state = .coreVM
            
            /// On iOS 13, this `asyncAfter` is required to make sure that subscription created by the time events start to
            /// be passed to publiser.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                coreViewModel.start()
            }
        }
        
        func subscribe(to eventsPublisher: OwnID.CoreSDK.CoreViewModel.EventPublisher, persistingEmail: OwnID.CoreSDK.Email) {
            registrationData.persistedEmail = persistingEmail
            coreViewModelBag.forEach { $0.cancel() }
            coreViewModelBag.removeAll()
            eventsPublisher
                .sink { [unowned self] completion in
                    if case .failure(let error) = completion {
                        handle(error)
                    }
                } receiveValue: { [unowned self] event in
                    switch event {
                    case .success(let payload):
                        OwnID.CoreSDK.logger.logCore(.entry(context: payload.context, Self.self))
                        switch payload.responseType {
                        case .registrationInfo:
                            self.registrationData.payload = payload
                            state = .ownidCreated
                            if let loginId = registrationData.payload?.loginId {
                                registrationData.persistedEmail = OwnID.CoreSDK.Email(rawValue: loginId)
                            }
                            resultPublisher.send(.success(.readyToRegister(usersEmailFromWebApp: registrationData.payload?.loginId, authType: registrationData.payload?.authType)))
                            
                        case .session:
                            processLogin(payload: payload)
                        }
                        
                    case .cancelled:
                        handle(.coreLog(entry: .errorEntry(context: registrationData.payload?.context, Self.self), error: .flowCancelled))
                        
                    case .loading:
                        resultPublisher.send(.success(.loading))
                    }
                }
                .store(in: &coreViewModelBag)
        }
        
        /// Used for custom button setup. Custom button sends events through this publisher
        /// and by doing that invokes flow.
        /// - Parameter buttonEventPublisher: publisher to subscribe to
        public func subscribe(to buttonEventPublisher: OwnID.UISDK.EventPubliser) {
            buttonEventPublisher
                .sink { _ in
                } receiveValue: { [unowned self] _ in
                    OwnID.CoreSDK.logger.logAnalytic(.registerClickMetric(action: .click, context: registrationData.payload?.context, hasLoginId: !email.isEmpty))
                    skipPasswordTapped(usersEmail: email)
                }
                .store(in: &bag)
        }
    }
}

private extension OwnID.FlowsSDK.RegisterView.ViewModel {
    
    func processLogin(payload: OwnID.CoreSDK.Payload) {
        let loginPerformerPublisher = loginPerformer.login(payload: payload, email: email)
        loginPerformerPublisher
            .sink { [unowned self] completion in
                if case .failure(let error) = completion {
                    handle(error)
                }
            } receiveValue: { [unowned self] registerResult in
                OwnID.CoreSDK.logger.logAnalytic(.loginTrackMetric(action: .loggedIn, context: payload.context, authType: payload.authType))
                state = .ownidCreated
                resultPublisher.send(.success(.userRegisteredAndLoggedIn(registrationResult: registerResult.operationResult, authType: registerResult.authType)))
                resetDataAndState(isResettingToInitialState: false)
            }
            .store(in: &bag)
    }
    
    func handle(_ error: OwnID.CoreSDK.CoreErrorLogWrapper) {
        resetToInitialState()
        OwnID.FlowsSDK.ErrorLogSender.sendLog(error: error)
        resultPublisher.send(.failure(error.error))
    }
}
