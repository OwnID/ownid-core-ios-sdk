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
                return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .localConfigIsNotPresent))
            }
            
            OwnID.UISDK.PopupManager.dismiss()
            OwnID.UISDK.showIdCollectView(store: state.idCollectViewStore,
                                          loginId: state.loginId,
                                          loginIdSettings: loginIdSettings)
            
            if #available(iOS 15.0, *) {
                let idCollectView = String(describing: OwnID.UISDK.IdCollect.IdCollectView.self)
                let eventCategory: OwnID.CoreSDK.EventCategory = state.type == .login ? .login : .registration
                OwnID.CoreSDK.eventService.sendMetric(.trackMetric(action: .screenShow(screen: idCollectView),
                                                                   category: eventCategory,
                                                                   context: state.context))
            }
            
            return []
        }
        
        func sendAuthRequest(state: inout OwnID.CoreSDK.CoreViewModel.State,
                             loginId: String) -> [Effect<Action>] {
            guard let urlString = step.startingData?.url, let url = URL(string: urlString) else {
                return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .dataIsMissing))
            }
            
            let context = state.context
            OwnID.CoreSDK.eventService.sendMetric(.trackMetric(action: .loginId, category: .login, context: context))

            let requestBody = IdCollectRequestBody(loginId: loginId, supportsFido2: OwnID.CoreSDK.isPasskeysSupported)
            state.loginId = loginId
            let effect = state.session.perform(url: url,
                                               method: .post,
                                               body: requestBody,
                                               with: StepResponse.self)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { response in
                    OwnID.CoreSDK.logger.log(.entry(context: context, level: .debug, message: "Id Collect Request Finished", Self.self))
                })
                .map { [self] in nextStepAction($0.step) }
                .catch { Just(Action.error(.coreLog(entry: .errorEntry(Self.self), error: $0))) }
                .eraseToEffect()
            
            return [effect]
        }
    }
}
