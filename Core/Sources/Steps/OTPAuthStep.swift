import Foundation
import Combine

extension OwnID.CoreSDK.CoreViewModel {
    private enum Constants {
        static let defaultOtpLenght = 4
    }
    
    struct OTPAuthRequestBody: Encodable {
        let code: String
    }

    class OTPAuthStep: BaseStep {
        private let step: Step
        
        init(step: Step) {
            self.step = step
        }
        
        override func run(state: inout OwnID.CoreSDK.CoreViewModel.State) -> [Effect<OwnID.CoreSDK.CoreViewModel.Action>] {
            guard let otpData = step.otpData, let restartUrl = URL(string: otpData.restartUrl) else {
                let message = OwnID.CoreSDK.ErrorMessage.dataIsMissing
                return errorEffect(.coreLog(error: .userError(errorModel: OwnID.CoreSDK.UserErrorModel(message: message)),
                                            isOnUI: true,
                                            type: Self.self))
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
                OwnID.CoreSDK.eventService.sendMetric(.trackMetric(action: .screenShow(screen: otpView),
                                                                   category: eventCategory,
                                                                   loginId: state.loginId))
            }
            
            return []
        }
        
        func restart(state: inout OwnID.CoreSDK.CoreViewModel.State) -> [Effect<Action>] {
            guard let otpData = step.otpData, let restartUrl = URL(string: otpData.restartUrl) else {
                let message = OwnID.CoreSDK.ErrorMessage.dataIsMissing
                return errorEffect(.coreLog(error: .userError(errorModel: OwnID.CoreSDK.UserErrorModel(message: message)),
                                            isOnUI: true,
                                            type: Self.self))
            }
            
            let context = state.context
            let eventCategory: OwnID.CoreSDK.EventCategory = state.type == .login ? .login : .registration
            OwnID.CoreSDK.eventService.sendMetric(.clickMetric(action: .noOTP, category: eventCategory, context: context, loginId: state.loginId))
            
            let effect = state.session.perform(url: restartUrl,
                                               method: .post,
                                               body: EmptyBody(),
                                               with: StepResponse.self)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { response in
                    OwnID.CoreSDK.logger.log(level: .debug, message: "Restart Code Request Finished", Self.self)
                })
                .map { [self] in handleResponse(response: $0, isOnUI: true) }
                .catch { Just(Action.error(.coreLog(error: $0, isOnUI: true, type: Self.self))) }
                .eraseToEffect()
            return [effect]
        }
        
        func resend(state: inout OwnID.CoreSDK.CoreViewModel.State) -> [Effect<Action>] {
            guard let otpData = step.otpData, let resendUrl = URL(string: otpData.resendUrl) else {
                let message = OwnID.CoreSDK.ErrorMessage.dataIsMissing
                return errorEffect(.coreLog(error: .userError(errorModel: OwnID.CoreSDK.UserErrorModel(message: message)),
                                            isOnUI: true,
                                            type: Self.self))
            }
            
            let context = state.context
            let eventCategory: OwnID.CoreSDK.EventCategory = state.type == .login ? .login : .registration
            OwnID.CoreSDK.eventService.sendMetric(.clickMetric(action: .noOTP, category: eventCategory, context: context, loginId: state.loginId))
            
            let effect = state.session.perform(url: resendUrl,
                                               method: .post,
                                               body: EmptyBody(),
                                               with: StepResponse.self)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { response in
                    OwnID.CoreSDK.logger.log(level: .debug, message: "Resend Code Request Finished", Self.self)
                })
                .map { [self] in handleResponse(response: $0, isOnUI: true) }
                .catch { Just(Action.error(.coreLog(error: $0, isOnUI: true, type: Self.self))) }
                .eraseToEffect()
            return [effect]
        }
        
        func sendCode(code: String, state: inout OwnID.CoreSDK.CoreViewModel.State) -> [Effect<Action>] {
            guard let otpData = step.otpData, let url = URL(string: otpData.url) else {
                let message = OwnID.CoreSDK.ErrorMessage.dataIsMissing
                return errorEffect(.coreLog(error: .userError(errorModel: OwnID.CoreSDK.UserErrorModel(message: message)),
                                            isOnUI: true,
                                            type: Self.self))
            }
            
            let context = state.context
            let eventCategory: OwnID.CoreSDK.EventCategory = state.type == .login ? .login : .registration
            let requestBody = OTPAuthRequestBody(code: code)
            let loginId = state.loginId
            let effect = state.session.perform(url: url,
                                               method: .post,
                                               body: requestBody,
                                               with: StepResponse.self)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { response in
                    OwnID.CoreSDK.logger.log(level: .debug, message: "Send Code Request Finished", Self.self)
                })
                .map({ [self] response in
                    if response.step != nil {
                        OwnID.CoreSDK.eventService.sendMetric(.trackMetric(action: .correctOTP,
                                                                           category: eventCategory,
                                                                           context: context,
                                                                           loginId: loginId))
                    } else if let error = response.error {
                        let model = OwnID.CoreSDK.UserErrorModel(code: error.errorCode, message: error.message, userMessage: error.userMessage)
                        if model.code == .invalidCode {
                            OwnID.CoreSDK.eventService.sendMetric(.errorMetric(action: .wrongOTP,
                                                                               category: eventCategory,
                                                                               context: context,
                                                                               loginId: loginId,
                                                                               errorMessage: error.message))
                        }
                    }

                    return handleResponse(response: response, isOnUI: true)
                })
                .catch { Just(Action.error(.coreLog(error: $0, isOnUI: true, type: Self.self))) }
                .eraseToEffect()
            return [effect]
        }
    }
}
