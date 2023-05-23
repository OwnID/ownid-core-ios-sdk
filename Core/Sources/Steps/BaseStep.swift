import Foundation
import Combine

extension OwnID.CoreSDK.CoreViewModel {
    class BaseStep {
        func run(state: inout State) -> [Effect<Action>] { return [] }
        
        func nextStepAction(_ step: Step) -> Action {
            let type = step.type
            switch type {
            case .starting:
                return .idCollect
            case .fido2Authorize:
                return .fido2Authorize(step: step)
            case .linkWithCode, .loginIDAuthorization, .verifyLoginID:
                return .oneTimePassword
            case .showQr:
                return .error(.coreLog(entry: .errorEntry(Self.self), error: .flowCancelled))
            case .success:
                return .success
            case .error:
                return .error(.coreLog(entry: .errorEntry(Self.self), error: .flowCancelled))
            }
        }
        
        func errorEffect(_ error: OwnID.CoreSDK.CoreErrorLogWrapper) -> [Effect<Action>] {
            [Just(.error(error)).eraseToEffect()]
        }
    }
}
