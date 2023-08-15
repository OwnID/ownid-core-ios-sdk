import Foundation
import Combine

extension OwnID.CoreSDK.CoreViewModel {
    struct IdCollectRequestBody: Encodable {
        let loginId: String
        let supportsFido2: Bool
    }

    class IdCollectStep: BaseStep {
        private let step: Step
        
        init(step: Step) {
            self.step = step
        }
        
        override func run(state: inout OwnID.CoreSDK.CoreViewModel.State) -> [Effect<OwnID.CoreSDK.CoreViewModel.Action>] {
            guard let loginIdSettings = state.configuration?.loginIdSettings else {
                let message = OwnID.CoreSDK.ErrorMessage.noLocalConfig
                return errorEffect(.coreLog(error: .userError(errorModel: OwnID.CoreSDK.UserErrorModel(message: message)), type: Self.self))
            }
            
            let idCollectViewStore = state.idCollectViewStore!
            let loginId = state.loginId
            OwnID.UISDK.PopupManager.dismissPopup(completion: {
                OwnID.UISDK.showIdCollectView(store: idCollectViewStore,
                                              loginId: loginId,
                                              loginIdSettings: loginIdSettings)
            })
            
            let idCollectView = String(describing: OwnID.UISDK.IdCollect.IdCollectView.self)
            let eventCategory: OwnID.CoreSDK.EventCategory = state.type == .login ? .login : .registration
            OwnID.CoreSDK.eventService.sendMetric(.trackMetric(action: .screenShow(screen: idCollectView),
                                                               category: eventCategory,
                                                               context: state.context,
                                                               loginId: state.loginId))
            
            return []
        }
        
        func sendAuthRequest(state: inout OwnID.CoreSDK.CoreViewModel.State,
                             loginId: String) -> [Effect<Action>] {
            guard let urlString = step.startingData?.url, let url = URL(string: urlString) else {
                let message = OwnID.CoreSDK.ErrorMessage.dataIsMissing
                return errorEffect(.coreLog(error: .userError(errorModel: OwnID.CoreSDK.UserErrorModel(message: message)),
                                            isOnUI: true,
                                            type: Self.self))
            }
            
            let context = state.context
            OwnID.CoreSDK.eventService.sendMetric(.trackMetric(action: .loginId, category: .login, context: context, loginId: state.loginId))

            let requestBody = IdCollectRequestBody(loginId: loginId, supportsFido2: OwnID.CoreSDK.isPasskeysSupported)
            state.loginId = loginId
            let effect = state.session.perform(url: url,
                                               method: .post,
                                               body: requestBody,
                                               with: StepResponse.self)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { response in
                    OwnID.CoreSDK.logger.log(level: .debug, message: "Id Collect Request Finished", Self.self)
                })
                .map { [self] in handleResponse(response: $0, isOnUI: true) }
                .catch { Just(.error(.coreLog(error: $0, isOnUI: true, type: Self.self))) }
                .eraseToEffect()
            
            return [effect]
        }
    }
}
