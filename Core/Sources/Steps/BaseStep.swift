import Foundation
import Combine

extension OwnID.CoreSDK.CoreViewModel {
    class StepResponse: Decodable {
        let step: Step
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
            case .error:
                let message = step.errorData?.userMessage ?? ""
                let code = step.errorData?.errorCode ?? ""
                return .error(.coreLog(entry: .errorEntry(Self.self),
                                       error: .serverErrorWithCode(message: message,
                                                                   code: code)))
            }
        }
        
        func errorEffect(_ error: OwnID.CoreSDK.CoreErrorLogWrapper) -> [Effect<Action>] {
            [Just(.error(error)).eraseToEffect()]
        }
    }
}
