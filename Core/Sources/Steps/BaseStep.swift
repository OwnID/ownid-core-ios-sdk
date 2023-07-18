import Foundation
import Combine

extension OwnID.CoreSDK.CoreViewModel {
    struct StepResponse: Decodable {
        let step: Step?
        let error: ErrorData?
    }
    
    class BaseStep {
        func run(state: inout State) -> [Effect<Action>] { return [] }
        
        func nextStepAction(_ step: Step) -> Action {
            let type = step.type
            switch type {
            case .starting:
                return .idCollect(step: step)
            case .fido2Authorize:
                return .fido2Authorize(step: step)
            case .linkWithCode, .loginIDAuthorization, .verifyLoginID:
                return .oneTimePassword(step: step)
            case .showQr:
                return .webApp(step: step)
            case .success:
                return .success
            }
        }
        
        func errorEffect(_ error: OwnID.CoreSDK.CoreErrorLogWrapper) -> [Effect<Action>] {
            [Just(.error(error)).eraseToEffect()]
        }
        
        func handleResponse(response: StepResponse, isOnUI: Bool) -> Action {
            if let step = response.step {
                return nextStepAction(step)
            } else if let error = response.error {
                let model = OwnID.CoreSDK.UserErrorModel(code: error.errorCode, message: error.message, userMessage: error.userMessage)
                return .error(.coreLog(error: .userError(errorModel: model),
                                       isOnUI: isOnUI,
                                       flowFinished: error.flowFinished ?? true,
                                       type: Self.self))
            }
            let message = OwnID.CoreSDK.ErrorMessage.requestError
            return .error(.coreLog(error: .userError(errorModel: OwnID.CoreSDK.UserErrorModel(message: message)),
                                   isOnUI: isOnUI,
                                   type: Self.self))
        }
    }
}
