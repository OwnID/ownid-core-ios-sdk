import Foundation
import Combine

extension OwnID.CoreSDK.CoreViewModel {
    private enum Constants {
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
            
            if #available(iOS 15.0, *) {
                let otpView = String(describing: OwnID.UISDK.OneTimePassword.OneTimePasswordView.self)
                let eventCategory: OwnID.CoreSDK.EventCategory = state.type == .login ? .login : .registration
                OwnID.CoreSDK.eventService.sendMetric(.trackMetric(action: .screenShow(screen: otpView), category: eventCategory))
            }
            
            return []
        }
        
        func restart(state: inout OwnID.CoreSDK.CoreViewModel.State) -> [Effect<Action>] {
            guard let otpData = step.otpData, let restartUrl = URL(string: otpData.restartUrl) else {
                return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .dataIsMissing))
            }
            
            let context = state.context
            let eventCategory: OwnID.CoreSDK.EventCategory = state.type == .login ? .login : .registration
            OwnID.CoreSDK.eventService.sendMetric(.clickMetric(action: .noOTP, category: eventCategory, context: context))
            
            let effect = state.session.perform(url: restartUrl,
                                               method: .post,
                                               body: EmptyBody(),
                                               with: OTPAuthResponse.self)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { response in
                    OwnID.CoreSDK.logger.log(.entry(context: context, level: .debug, message: "Restart Code Request Finished", Self.self))
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
            let eventCategory: OwnID.CoreSDK.EventCategory = state.type == .login ? .login : .registration
            let requestBody = OTPAuthRequestBody(code: code)
            let effect = state.session.perform(url: url,
                                               method: .post,
                                               body: requestBody,
                                               with: OTPAuthResponse.self)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { response in
                    OwnID.CoreSDK.logger.log(.entry(context: context, level: .debug, message: "Send Code Request Finished", Self.self))
                })
                .map({ [self] response in
                    if let step = response.step {
                        OwnID.CoreSDK.eventService.sendMetric(.trackMetric(action: .correctOTP, category: eventCategory, context: context))
                        return nextStepAction(step)
                    } else if let error = response.error {
                        OwnID.CoreSDK.eventService.sendMetric(.errorMetric(action: .wrongOTP,
                                                                           category: eventCategory,
                                                                           context: context,
                                                                           errorMessage: error.message))
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
