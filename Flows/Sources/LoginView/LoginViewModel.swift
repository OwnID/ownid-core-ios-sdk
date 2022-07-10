
import Foundation
import Combine
import OwnIDCoreSDK

extension OwnID.FlowsSDK.LoginView.ViewModel {
    enum State {
        case initial
        case coreVM
        case loggedIn
    }
}

public extension OwnID.FlowsSDK.LoginView {
    final class ViewModel: ObservableObject {
        @Published private(set) var state = State.initial
        private var bag = Set<AnyCancellable>()
        private var coreViewModelBag = Set<AnyCancellable>()
        private let resultPublisher = PassthroughSubject<Result<OwnID.FlowsSDK.LoginEvent, OwnID.CoreSDK.Error>, Never>()
        private let loginPerformer: LoginPerformer
        private var payload: OwnID.CoreSDK.Payload?
        var coreViewModel: OwnID.CoreSDK.CoreViewModel!
        
        let sdkConfigurationName: String
        let webLanguages: OwnID.CoreSDK.Languages
        var getEmail: (() -> String)!
        
        public var eventPublisher: OwnID.FlowsSDK.LoginPublisher {
            resultPublisher.eraseToAnyPublisher()
        }
        
        public init(loginPerformer: LoginPerformer,
                    sdkConfigurationName: String,
                    webLanguages: OwnID.CoreSDK.Languages) {
            OwnID.CoreSDK.logger.logAnalytic(.loginTrackMetric(action: "OwnID Widget is Loaded", context: payload?.context))
            self.sdkConfigurationName = sdkConfigurationName
            self.loginPerformer = loginPerformer
            self.webLanguages = webLanguages
        }
        
        public func resetDataAndState() {
            payload = .none
            coreViewModel = .none
            state = .initial
        }
        
        public func resetState() {
            coreViewModel = .none
            state = .initial
        }
        
        func skipPasswordTapped(usersEmail: String) {
            DispatchQueue.main.async { [self] in
                coreViewModelBag.removeAll()
                let email = OwnID.CoreSDK.Email(rawValue: usersEmail)
                coreViewModel = OwnID.CoreSDK.shared.createCoreViewModelForLogIn(email: email,
                                                                                 sdkConfigurationName: sdkConfigurationName,
                                                                                 webLanguages: webLanguages)
                subscribe(to: coreViewModel.eventPublisher)
                state = .coreVM
                coreViewModel.start()
            }
        }
        
        func subscribe(to eventsPublisher: OwnID.CoreSDK.EventPublisher) {
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
                        handle(.flowCancelled)
                        
                    case .loading:
                        resultPublisher.send(.success(.loading))
                    }
                }
                .store(in: &coreViewModelBag)
        }
        
        func subscribe(to passwordEventsPublisher: OwnID.UISDK.EventPubliser) {
            passwordEventsPublisher
                .sink { _ in
                } receiveValue: { [unowned self] event in
                    OwnID.CoreSDK.logger.logAnalytic(.loginClickMetric(action: "Clicked Skip Password", context: payload?.context))
                    skipPasswordTapped(usersEmail: getEmail())
                }
                .store(in: &bag)
        }
    }
}

private extension OwnID.FlowsSDK.LoginView.ViewModel {
    func process(payload: OwnID.CoreSDK.Payload) {
        self.payload = payload
        let loginPerformerPublisher = loginPerformer.login(payload: payload, email: getEmail())
        loginPerformerPublisher
            .sink { [unowned self] completion in
                if case .failure(let error) = completion {
                    handle(error)
                }
            } receiveValue: { [unowned self] loginResult in
                OwnID.CoreSDK.logger.logAnalytic(.loginTrackMetric(action: "User is Logged in", context: payload.context))
                state = .loggedIn
                resultPublisher.send(.success(.loggedIn(loginResult: loginResult)))
                resetDataAndState()
            }
            .store(in: &bag)
    }
    
    func handle(_ error: OwnID.CoreSDK.Error) {
        OwnID.CoreSDK.logger.logFlow(.errorEntry(message: "\(error.localizedDescription)", Self.self))
        resetDataAndState()
        resultPublisher.send(.failure(error))
    }
}
