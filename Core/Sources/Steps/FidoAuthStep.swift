import Foundation
import Combine

extension OwnID.CoreSDK.CoreViewModel {
    struct AuthRequestBody: Encodable {
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            if let fido2Payload = fido2Payload as? OwnID.CoreSDK.Fido2LoginPayload {
                try container.encode(fido2Payload, forKey: .result)
            }
            if let fido2Payload = fido2Payload as? OwnID.CoreSDK.Fido2RegisterPayload {
                try container.encode(fido2Payload, forKey: .result)
            }
        }
        
        let type: OwnID.CoreSDK.RequestType
        let fido2Payload: Encodable
        
        enum CodingKeys: CodingKey {
            case type
            case result
        }
    }
    
    class FidoAuthStep: BaseStep {
        private let step: Step
        
        init(step: Step) {
            self.step = step
        }
        
        override func run(state: inout State) -> [Effect<OwnID.CoreSDK.CoreViewModel.Action>] {
            guard let url = step.fidoData?.url else {
                return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .urlIsMissing))
            }
            
            if #available(iOS 16, *),
               let domain = step.fidoData?.relyingPartyId {
                let authManager = state.createAccountManagerClosure(state.authManagerStore, domain, state.context, url)
                switch state.type {
                case .register:
                    authManager.signUpWith(userName: state.loginId)
                case .login:
                    authManager.signIn()
                }
                state.authManager = authManager
            }
            
            return []
        }
        
        func sendAuthRequest(state: inout OwnID.CoreSDK.CoreViewModel.State,
                             fido2Payload: Encodable) -> [Effect<Action>] {
            guard let urlString = step.fidoData?.url, let url = URL(string: urlString) else {
                return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .dataIsMissing))
            }

            let context = state.context
            let requestBody = AuthRequestBody(type: state.type,
                                              fido2Payload: fido2Payload)
            let effect = state.session.perform(url: url,
                                               method: .post,
                                               body: requestBody,
                                               with: StepResponse.self)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { response in
                    OwnID.CoreSDK.logger.logCore(.entry(context: context, message: "Auth Request Finished", Self.self))
                })
                .map { [self] in nextStepAction($0.step) }
                .catch { error in
                    let coreError: OwnID.CoreSDK.Error
                    switch error {
                    case OwnID.CoreSDK.ServiceError.networkFailed(let error):
                        coreError = .authRequestNetworkFailed(underlying: error)
                    case OwnID.CoreSDK.ServiceError.encodeFailed(let error):
                        coreError = .authRequestBodyEncodeFailed(underlying: error)
                    case OwnID.CoreSDK.ServiceError.decodeFailed(let error):
                        coreError = .authRequestResponseDecodeFailed(underlying: error)
                    case OwnID.CoreSDK.ServiceError.responseIsEmpty:
                        coreError = .authRequestResponseIsEmpty
                    }
                    return Just(Action.error(.coreLog(entry: .errorEntry(Self.self), error: coreError)))
                }
                .eraseToEffect()
            
            return [effect]
        }
    }
}
