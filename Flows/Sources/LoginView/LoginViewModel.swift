import Foundation
import Combine

extension OwnID.FlowsSDK.LoginView.ViewModel {
    enum State {
        case initial
        case coreVM
        case loggedIn
    }
}

extension OwnID.FlowsSDK.LoginView.ViewModel.State {
    var buttonState: OwnID.UISDK.ButtonState {
        switch self {
        case .initial, .coreVM:
            return .enabled
            
        case .loggedIn:
            return .activated
        }
    }
    
    var isLoading: Bool {
        switch self {
        case .coreVM:
            return true
            
        case .loggedIn, .initial:
            return false
        }
    }
}

public extension OwnID.FlowsSDK.LoginView {
    final class ViewModel: ObservableObject {
        @Published private(set) var state = State.initial
        @Published public var shouldShowTooltip = true
        
        private var bag = Set<AnyCancellable>()
        private var coreViewModelBag = Set<AnyCancellable>()
        private let resultPublisher = PassthroughSubject<Result<OwnID.FlowsSDK.LoginEvent, OwnID.CoreSDK.Error>, Never>()
        private let loginPerformer: LoginPerformer
        private var payload: OwnID.CoreSDK.Payload?
        private var email = ""
        var coreViewModel: OwnID.CoreSDK.CoreViewModel!
        var currentMetadata: OwnID.CoreSDK.MetricLogEntry.CurrentMetricInformation?
        
        let sdkConfigurationName: String
        
        public var eventPublisher: OwnID.LoginPublisher {
            resultPublisher.eraseToAnyPublisher()
        }
        
        public init(loginPerformer: LoginPerformer,
                    sdkConfigurationName: String,
                    emailPublisher: OwnID.CoreSDK.EmailPublisher) {
            self.sdkConfigurationName = sdkConfigurationName
            self.loginPerformer = loginPerformer
            updateEmailPublisher(emailPublisher)
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
            OwnID.CoreSDK.logger.logAnalytic(.loginTrackMetric(action: .loaded, context: payload?.context))
        }
        
        public func updateEmailPublisher(_ emailPublisher: OwnID.CoreSDK.EmailPublisher) {
            emailPublisher.assign(to: \.email, on: self).store(in: &bag)
        }
        
        /// Reset visual state and any possible data from web flow
        public func resetDataAndState(isResettingToInitialState: Bool = true) {
            payload = .none
            resetToInitialState()
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
            switch state {
            case .initial:
                DispatchQueue.main.async { [self] in
                    let email = OwnID.CoreSDK.Email(rawValue: usersEmail)
                    let coreViewModel = OwnID.CoreSDK.shared.createCoreViewModelForLogIn(email: email, sdkConfigurationName: sdkConfigurationName)
                    self.coreViewModel = coreViewModel
                    subscribe(to: coreViewModel.eventPublisher)
                    state = .coreVM
                    
                    /// On iOS 13, this `asyncAfter` is required to make sure that subscription created by the time events start to
                    /// be passed to publiser.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        coreViewModel.start()
                    }
                }
                
            case .coreVM:
                resetToInitialState()
                
            case .loggedIn:
                break
            }
        }
        
        func subscribe(to eventsPublisher: OwnID.CoreSDK.EventPublisher) {
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
                        process(payload: payload)
                        
                    case .cancelled:
                        handle(.coreLog(entry: .errorEntry(context: payload?.context, Self.self), error: .flowCancelled))
                        
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
                } receiveValue: { [unowned self] event in
                    if state == .initial {
                        OwnID.CoreSDK.logger.logAnalytic(.loginClickMetric(context: payload?.context, hasLoginId: !email.isEmpty))
                    }
                    skipPasswordTapped(usersEmail: email)
                }
                .store(in: &bag)
        }
    }
}

private extension OwnID.FlowsSDK.LoginView.ViewModel {
    func process(payload: OwnID.CoreSDK.Payload) {
        self.payload = payload
        let loginPerformerPublisher = loginPerformer.login(payload: payload, email: email)
        loginPerformerPublisher
            .sink { [unowned self] completion in
                if case .failure(let error) = completion {
                    handle(error)
                }
            } receiveValue: { [unowned self] loginResult in
                OwnID.CoreSDK.logger.logAnalytic(.loginTrackMetric(action: .loggedIn,
                                                                   context: payload.context,
                                                                   authType: payload.authType))
                OwnID.CoreSDK.DefaultsEmailSaver.save(email: email)
                state = .loggedIn
                resultPublisher.send(.success(.loggedIn(loginResult: loginResult.operationResult, authType: loginResult.authType)))
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
