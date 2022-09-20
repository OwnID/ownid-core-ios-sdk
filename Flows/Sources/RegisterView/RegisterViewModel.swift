import Foundation
import Combine
import OwnIDCoreSDK

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
        var coreViewModel: OwnID.CoreSDK.CoreViewModel!
        
        let sdkConfigurationName: String
        let webLanguages: OwnID.CoreSDK.Languages
        public var getEmail: (() -> String)!
        
        public var eventPublisher: OwnID.FlowsSDK.RegistrationPublisher {
            resultPublisher.eraseToAnyPublisher()
        }
        
        public init(registrationPerformer: RegistrationPerformer,
                    sdkConfigurationName: String,
                    webLanguages: OwnID.CoreSDK.Languages) {
            OwnID.CoreSDK.logger.logAnalytic(.registerTrackMetric(action: "OwnID Widget is Loaded", context: registrationData.payload?.context))
            self.sdkConfigurationName = sdkConfigurationName
            self.registrationPerformer = registrationPerformer
            self.webLanguages = webLanguages
        }
        
        public func register(with email: String,
                             registerParameters: RegisterParameters = EmptyRegisterParameters()) {
            if email.isEmpty {
                handle(.plugin(error: OwnID.FlowsSDK.RegisterError.emailIsMissing))
                return
            }
            guard let payload = registrationData.payload else { handle(.payloadMissing(underlying: .none)); return }
            let persisted = registrationData.persistedEmail
            if !persisted.rawValue.isEmpty,
               email.lowercased() != persisted.rawValue {
                handle(.plugin(error: OwnID.FlowsSDK.RegisterError.enteredEmailMismatch))
                return
            }
            if let webAppEmail = registrationData.payload?.loginId, !webAppEmail.isEmpty, email.lowercased() != webAppEmail {
                handle(.plugin(error: OwnID.FlowsSDK.RegisterError.enteredEmailMismatch))
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
                    OwnID.CoreSDK.logger.logAnalytic(.registerTrackMetric(action: "User is Registered", context: payload.context))
                    resultPublisher.send(.success(.userRegisteredAndLoggedIn(registrationResult: registrationResult)))
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
                resultPublisher.send(.success(.readyToRegister(usersEmailFromWebApp: usersEmail)))
                return
            }
            let email = OwnID.CoreSDK.Email(rawValue: usersEmail)
            coreViewModel = OwnID.CoreSDK.shared.createCoreViewModelForRegister(email: email,
                                                                                sdkConfigurationName: sdkConfigurationName,
                                                                                webLanguages: webLanguages)
            subscribe(to: coreViewModel.eventPublisher, persistingEmail: email)
            state = .coreVM
            coreViewModel.start()
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
                        self.registrationData.payload = payload
                        sendSuccess()
                        
                    case .cancelled:
                        handle(.flowCancelled)
                        
                    case .loading:
                        resultPublisher.send(.success(.loading))
                    }
                }
                .store(in: &bag)
        }
        
        public func subscribe(to passwordEventsPublisher: OwnID.UISDK.EventPubliser) {
            passwordEventsPublisher
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
    func sendSuccess() {
        OwnID.CoreSDK.logger.logFlow(.entry(Self.self))
        state = .ownidCreated
        resultPublisher.send(.success(.readyToRegister(usersEmailFromWebApp: registrationData.payload?.loginId)))
    }
    
    func handle(_ error: OwnID.CoreSDK.Error) {
        OwnID.CoreSDK.logger.logFlow(.errorEntry(message: "\(error.localizedDescription)", Self.self))
        resultPublisher.send(.failure(error))
    }
}
