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
            let oneTimePasswordStore = state.oneTimePasswordStore!
            let loginId = state.loginId
            OwnID.UISDK.PopupManager.dismissPopup(completion: {
                OwnID.UISDK.showOTPView(store: oneTimePasswordStore,
                                        loginId: loginId,
                                        otpLength: otpLength,
                                        restartUrl: restartUrl,
                                        type: self.step.type,
                                        verificationType: otpData.verificationType)
            })
            
            if #available(iOS 15.0, *) {
                let otpView = String(describing: OwnID.UISDK.OneTimePassword.OneTimePasswordView.self)
                let eventCategory: OwnID.CoreSDK.EventCategory = state.type == .login ? .login : .registration
                OwnID.CoreSDK.eventService.sendMetric(.trackMetric(action: .screenShow(screen: otpView),
                                                                   category: eventCategory,
                                                                   loginId: state.loginId))
            }
            
            return []
        }
        
        private func stopAndInit(state: inout OwnID.CoreSDK.CoreViewModel.State) -> [Effect<Action>] {
            let effect = state.session.perform(url: state.stopUrl,
                                               method: .post,
                                               body: EmptyBody(),
                                               with: EmptyBody.self)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { response in
                    OwnID.CoreSDK.logger.log(level: .debug, message: "Stop Request Finished", Self.self)
                })
                .map { _ in Action.sendInitialRequest }
                .catch { _ in Just(Action.sendInitialRequest) }
                .eraseToEffect()
            return [effect]
        }
        
        func restart(state: inout OwnID.CoreSDK.CoreViewModel.State, isFlowFinished: Bool) -> [Effect<Action>] {
            guard let otpData = step.otpData, let restartUrl = URL(string: otpData.restartUrl) else {
                let message = OwnID.CoreSDK.ErrorMessage.dataIsMissing
                return errorEffect(.coreLog(error: .userError(errorModel: OwnID.CoreSDK.UserErrorModel(message: message)),
                                            isOnUI: true,
                                            type: Self.self))
            }
            
            let context = state.context
            let eventCategory: OwnID.CoreSDK.EventCategory = state.type == .login ? .login : .registration
            OwnID.CoreSDK.eventService.sendMetric(.clickMetric(action: .notYou, category: eventCategory, context: context, loginId: state.loginId))
            
            if let enableRegistrationFromLogin = state.configuration?.enableRegistrationFromLogin, enableRegistrationFromLogin {
                guard !isFlowFinished else {
                    state.shouldIgnoreLoginIdOnInit = true
                    return stopAndInit(state: &state)
                }
                
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
            } else {
                return [Just(Action.notYouCancel).eraseToEffect()]
            }
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
                .map { [self] response in
                    if let type = response.step?.type {
                        switch type {
                        case .linkWithCode, .loginIDAuthorization, .verifyLoginID:
                            return .sameStep
                        default:
                            return handleResponse(response: response, isOnUI: true)
                        }
                    } else {
                        return handleResponse(response: response, isOnUI: true)
                    }
                }
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
