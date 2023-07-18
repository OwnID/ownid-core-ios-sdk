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
    
    struct FidoErrorRequestBody: Encodable {
        let type: OwnID.CoreSDK.RequestType
        let error: Error
        
        struct Error: Encodable {
            let name: String
            let type: String
            let code: Int
            let message: String
        }

    }
    
    class FidoAuthStep: BaseStep {
        private let step: Step
        private var type = OwnID.CoreSDK.RequestType.register
        
        init(step: Step) {
            self.step = step
        }
        
        override func run(state: inout State) -> [Effect<OwnID.CoreSDK.CoreViewModel.Action>] {
            guard let url = step.fidoData?.url else {
                let message = OwnID.CoreSDK.ErrorMessage.dataIsMissing
                return errorEffect(.coreLog(error: .userError(errorModel: OwnID.CoreSDK.UserErrorModel(message: message)), type: Self.self))
            }
            
            let eventCategory: OwnID.CoreSDK.EventCategory = state.type == .login ? .login : .registration
            OwnID.CoreSDK.logger.log(level: .debug, message: "run Fido \(type.rawValue)", Self.self)
            OwnID.CoreSDK.eventService.sendMetric(.trackMetric(action: .fidoRun(category: eventCategory),
                                                               category: eventCategory,
                                                               context: state.context,
                                                               loginId: state.loginId))
            if #available(iOS 16, *),
               let domain = step.fidoData?.relyingPartyId {
                let authManager = state.createAccountManagerClosure(state.authManagerStore, domain, state.context, url)
                if let credId = step.fidoData?.credId {
                    authManager.signIn(credId: credId)
                } else {
                    authManager.signUpWith(userName: state.loginId)
                }

                state.authManager = authManager
            }
            
            return []
        }
        
        func sendAuthRequest(state: inout OwnID.CoreSDK.CoreViewModel.State,
                             fido2Payload: Encodable,
                             type: OwnID.CoreSDK.RequestType) -> [Effect<Action>] {
            guard let urlString = step.fidoData?.url, let url = URL(string: urlString) else {
                let message = OwnID.CoreSDK.ErrorMessage.dataIsMissing
                return errorEffect(.coreLog(error: .userError(errorModel: OwnID.CoreSDK.UserErrorModel(message: message)), type: Self.self))
            }

            self.type = type
            let context = state.context
            let eventCategory: OwnID.CoreSDK.EventCategory = state.type == .login ? .login : .registration
            
            OwnID.CoreSDK.eventService.sendMetric(.trackMetric(action: .fidoFinished(category: eventCategory),
                                                               category: eventCategory,
                                                               context: context,
                                                               loginId: state.loginId))
            
            let requestBody = AuthRequestBody(type: type,
                                              fido2Payload: fido2Payload)
            let effect = state.session.perform(url: url,
                                               method: .post,
                                               body: requestBody,
                                               with: StepResponse.self)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { response in
                    OwnID.CoreSDK.logger.log(level: .debug, message: "Auth Request Finished", Self.self)
                })
                .map { [self] in handleResponse(response: $0, isOnUI: false) }
                .catch { Just(Action.error(.coreLog(error: $0, type: Self.self))) }
                .eraseToEffect()
            
            return [effect]
        }
        
        func handleFidoError(state: inout OwnID.CoreSDK.CoreViewModel.State,
                             error: OwnID.CoreSDK.AccountManager.AuthManagerError) -> [Effect<Action>] {
            guard let urlString = step.fidoData?.url, let url = URL(string: urlString) else {
                let message = OwnID.CoreSDK.ErrorMessage.dataIsMissing
                return errorEffect(.coreLog(error: .userError(errorModel: OwnID.CoreSDK.UserErrorModel(message: message)), type: Self.self))
            }
            
            let fidoError: OwnID.CoreSDK.CoreViewModel.FidoErrorRequestBody.Error
            
            switch error {
            case .authorizationManagerAuthError(let error), .authorizationManagerGeneralError(let error):
                let error = error as NSError
                fidoError = OwnID.CoreSDK.CoreViewModel.FidoErrorRequestBody.Error(name: error.domain,
                                                                                   type: error.domain,
                                                                                   code: error.code,
                                                                                   message: error.localizedDescription)
            case .authorizationManagerCredintialsNotFoundOrCanlelledByUser(let error):
                let error = error as NSError
                fidoError = OwnID.CoreSDK.CoreViewModel.FidoErrorRequestBody.Error(name: error.domain,
                                                                                   type: error.domain,
                                                                                   code: error.code,
                                                                                   message: error.localizedDescription)
            default:
                fidoError = OwnID.CoreSDK.CoreViewModel.FidoErrorRequestBody.Error(name: error.errorDescription,
                                                                                   type: error.errorDescription,
                                                                                   code: 0,
                                                                                   message: error.errorDescription)
            }
            
            let eventCategory: OwnID.CoreSDK.EventCategory = state.type == .login ? .login : .registration
            let context = state.context
            OwnID.CoreSDK.eventService.sendMetric(.errorMetric(action: .fidoNotFinished(category: eventCategory),
                                                               category: eventCategory,
                                                               context: context,
                                                               loginId: state.loginId,
                                                               errorMessage: error.localizedDescription))
            
            let requestBody = FidoErrorRequestBody(type: type,
                                                   error: fidoError)
            let effect = state.session.perform(url: url,
                                               method: .post,
                                               body: requestBody,
                                               with: StepResponse.self)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { response in
                    OwnID.CoreSDK.logger.log(level: .debug, message: "Error Request Finished", Self.self)
                })
                .map { [self] in handleResponse(response: $0, isOnUI: false) }
                .catch { Just(Action.error(.coreLog(error: $0, type: Self.self))) }
                .eraseToEffect()
            return [effect]
        }
    }
}
