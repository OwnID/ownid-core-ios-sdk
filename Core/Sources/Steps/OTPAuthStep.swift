import Foundation
import Combine

extension OwnID.CoreSDK.CoreViewModel {
    private struct Constants {
        static let defaultOtpLenght = 4
    }
    
    struct OTPAuthRequestBody: Encodable {
        let code: String
    }
    
    struct OTPAuthResponse: Decodable {
        let step: Step?
        let error: ErrorStepData?
    }
    
    class OTPAuthStep: BaseStep {
        private let step: Step
        
        init(step: Step) {
            self.step = step
        }
        
        override func run(state: inout OwnID.CoreSDK.CoreViewModel.State) -> [Effect<OwnID.CoreSDK.CoreViewModel.Action>] {
            guard let otpData = step.otpData, let restartUrl = URL(string: otpData.restartUrl) else {
                return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .dataIsMissing))
            }
            
            let otpLength = otpData.otpLength ?? Constants.defaultOtpLenght
            OwnID.UISDK.PopupManager.dismiss()
            OwnID.UISDK.showOTPView(store: state.oneTimePasswordStore,
                                    loginId: state.loginId,
                                    otpLength: otpLength,
                                    restartUrl: restartUrl,
                                    type: step.type,
                                    verificationType: otpData.verificationType)
            return []
        }
        
        func restart(state: inout OwnID.CoreSDK.CoreViewModel.State) -> [Effect<Action>] {
            guard let otpData = step.otpData, let restartUrl = URL(string: otpData.restartUrl) else {
                return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .dataIsMissing))
            }
            
            let context = state.context
            let effect = state.session.perform(url: restartUrl,
                                               method: .post,
                                               body: EmptyBody(),
                                               with: OTPAuthResponse.self)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { response in
                    OwnID.CoreSDK.logger.logCore(.entry(context: context, message: "Restart Code Request Finished", Self.self))
                })
                .map({ [self] response in
                    guard let step = response.step else {
                        return Action.error(.coreLog(entry: .errorEntry(Self.self), error: .requestResponseIsEmpty))
                    }
                    return nextStepAction(step)
                })
                .catch { Just(Action.error(.coreLog(entry: .errorEntry(Self.self), error: $0))) }
                .eraseToEffect()
            return [effect]
        }
        
        func sendCode(code: String, state: inout OwnID.CoreSDK.CoreViewModel.State) -> [Effect<Action>] {
            guard let otpData = step.otpData, let url = URL(string: otpData.url) else {
                return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .dataIsMissing))
            }
            
            let context = state.context
            let requestBody = OTPAuthRequestBody(code: code)
            let effect = state.session.perform(url: url,
                                               method: .post,
                                               body: requestBody,
                                               with: OTPAuthResponse.self)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { response in
                    OwnID.CoreSDK.logger.logCore(.entry(context: context, message: "Send Code Request Finished", Self.self))
                })
                .map({ [self] response in
                    if let step = response.step {
                        return nextStepAction(step)
                    } else if let _ = response.error {
                        return .nonTerminalError
                    }
                    
                    return Action.error(.coreLog(entry: .errorEntry(Self.self), error: .requestResponseIsEmpty))
                })
                .catch { Just(Action.error(.coreLog(entry: .errorEntry(Self.self), error: $0))) }
                .eraseToEffect()
            return [effect]
        }
    }
}
