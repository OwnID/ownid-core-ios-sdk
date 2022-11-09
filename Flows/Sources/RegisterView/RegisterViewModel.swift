import Foundation
import Combine

extension OwnID.FlowsSDK.RegisterView.ViewModel {
    enum State {
        case initial
        case coreVM
        case ownidCreated
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
        
        /// Checks email if it is valid for tooltip display
        public var shouldShowTooltipEmailProcessingClosure: ((String?) -> Bool) = { emailString in
            guard let emailString = emailString else { return false }
            let emailObject = OwnID.CoreSDK.Email(rawValue: emailString)
            return emailObject.isValid
        }
        
        private var bag = Set<AnyCancellable>()
        private var coreViewModelBag = Set<AnyCancellable>()
        private let resultPublisher = PassthroughSubject<Result<OwnID.FlowsSDK.RegistrationEvent, OwnID.CoreSDK.Error>, Never>()
        private let registrationPerformer: RegistrationPerformer
        private var registrationData = RegistrationData()
        private let loginPerformer: LoginPerformer
        var coreViewModel: OwnID.CoreSDK.CoreViewModel!
        
        let sdkConfigurationName: String
        let webLanguages: OwnID.CoreSDK.Languages
        public var getEmail: (() -> String)!
        
        public var eventPublisher: OwnID.FlowsSDK.RegistrationPublisher {
            resultPublisher.eraseToAnyPublisher()
        }
        
        public init(registrationPerformer: RegistrationPerformer,
                    loginPerformer: LoginPerformer,
                    sdkConfigurationName: String,
                    webLanguages: OwnID.CoreSDK.Languages) {
            OwnID.CoreSDK.logger.logAnalytic(.registerTrackMetric(action: "OwnID Widget is Loaded", context: registrationData.payload?.context))
            self.sdkConfigurationName = sdkConfigurationName
            self.registrationPerformer = registrationPerformer
            self.loginPerformer = loginPerformer
            self.webLanguages = webLanguages
        }
        
        public func register(with email: String,
                             registerParameters: RegisterParameters = EmptyRegisterParameters()) {
            if email.isEmpty {
                handle(.plugin(error: OwnID.FlowsSDK.RegisterError.emailIsMissing))
                return
            }
            guard let payload = registrationData.payload else { handle(.payloadMissing(underlying: .none)); return }
            let config = OwnID.FlowsSDK.RegistrationConfiguration(payload: payload,
                                                                  email: OwnID.CoreSDK.Email(rawValue: email))
            registrationPerformer.register(configuration: config, parameters: registerParameters)
                .sink { [unowned self] completion in
                    if case .failure(let error) = completion {
                        handle(error)
                    }
                } receiveValue: { [unowned self] registrationResult in
                    OwnID.CoreSDK.logger.logAnalytic(.registerTrackMetric(action: "User is Registered", context: payload.context))
                    resultPublisher.send(.success(.userRegisteredAndLoggedIn(registrationResult: registrationResult.operationResult, authType: registrationResult.authType)))
                    resetDataAndState()
                }
                .store(in: &bag)
        }
        
        /// Reset visual state and any possible data from web flow
        public func resetDataAndState() {
            registrationData = RegistrationData()
            resetState()
        }
        
        /// Reset visual state
        public func resetState() {
            coreViewModelBag.removeAll()
            coreViewModel = .none
            state = .initial
        }
        
        func skipPasswordTapped(usersEmail: String) {
            if case .ownidCreated = state {
                OwnID.CoreSDK.logger.logAnalytic(.registerClickMetric(action: "Clicked Skip Password Undo", context: registrationData.payload?.context))
                resetState()
                resultPublisher.send(.success(.resetTapped))
                return
            }
            if registrationData.payload != nil {
                state = .ownidCreated
                resultPublisher.send(.success(.readyToRegister(usersEmailFromWebApp: usersEmail, authType: registrationData.payload?.authType)))
                return
            }
            let email = OwnID.CoreSDK.Email(rawValue: usersEmail)
            let coreViewModel = OwnID.CoreSDK.shared.createCoreViewModelForRegister(email: email,
                                                                                sdkConfigurationName: sdkConfigurationName,
                                                                                webLanguages: webLanguages)
            self.coreViewModel = coreViewModel
            subscribe(to: coreViewModel.eventPublisher, persistingEmail: email)
            state = .coreVM
            
            /// On iOS 13, this `asyncAfter` is required to make sure that subscription created by the time events start to
            /// be passed to publiser.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                coreViewModel.start()
            }
        }
        
        func subscribe(to eventsPublisher: OwnID.CoreSDK.EventPublisher, persistingEmail: OwnID.CoreSDK.Email) {
            registrationData.persistedEmail = persistingEmail
            eventsPublisher
                .sink { [unowned self] completion in
                    if case .failure(let error) = completion {
                        handle(error)
                    }
                } receiveValue: { [unowned self] event in
                    switch event {
                    case .success(let payload):
                        OwnID.CoreSDK.logger.logFlow(.entry(Self.self))
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
                        handle(.flowCancelled)
                        
                    case .loading:
                        resultPublisher.send(.success(.loading))
                    }
                }
                .store(in: &bag)
        }
        
        /// Used for custom button setup. Custom button sends events through this publisher
        /// and by doing that invokes flow.
        /// - Parameter buttonEventPublisher: publisher to subscribe to
        public func subscribe(to buttonEventPublisher: OwnID.UISDK.EventPubliser) {
            buttonEventPublisher
                .sink { _ in
                } receiveValue: { [unowned self] _ in
                    OwnID.CoreSDK.logger.logAnalytic(.registerClickMetric(action: "Clicked Skip Password", context: registrationData.payload?.context))
                        skipPasswordTapped(usersEmail: getEmail())
                }
                .store(in: &bag)
        }
    }
}

private extension OwnID.FlowsSDK.RegisterView.ViewModel {
    func processLogin(payload: OwnID.CoreSDK.Payload) {
        let loginPerformerPublisher = loginPerformer.login(payload: payload, email: getEmail())
        loginPerformerPublisher
            .sink { [unowned self] completion in
                if case .failure(let error) = completion {
                    handle(error)
                }
            } receiveValue: { [unowned self] registerResult in
                OwnID.CoreSDK.logger.logAnalytic(.loginTrackMetric(action: "User is Logged in", context: payload.context, authType: payload.authType))
                state = .ownidCreated
                resultPublisher.send(.success(.userRegisteredAndLoggedIn(registrationResult: registerResult.operationResult, authType: registerResult.authType)))
                resetDataAndState()
            }
            .store(in: &bag)
    }
    
    func handle(_ error: OwnID.CoreSDK.Error) {
        OwnID.CoreSDK.logger.logFlow(.errorEntry(message: "\(error.localizedDescription)", Self.self))
        resultPublisher.send(.failure(error))
    }
}
