import Foundation
import Combine

extension OwnID.CoreSDK.CoreViewModel {
    struct EmptyBody: Codable { }
    
    class StopStep: BaseStep {
        override func run(state: inout State) -> [Effect<OwnID.CoreSDK.CoreViewModel.Action>] {
            let context = state.context
            
            OwnID.CoreSDK.logger.log(.entry(level: .information, message: "Cancel Flow", Self.self))
            OwnID.CoreSDK.eventService.sendMetric(.trackMetric(action: .cancel,
                                                               category: state.type == .login ? .login : .registration,
                                                               context: context))
            
            let effect = state.session.perform(url: state.stopUrl,
                                               method: .post,
                                               body: EmptyBody(),
                                               with: EmptyBody.self)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { response in
                    OwnID.CoreSDK.logger.log(.entry(context: context, level: .debug, message: "Stop Request Finished", Self.self))
                })
                .map { _ in Action.stopRequestLoaded }
                .catch { _ in Just(Action.stopRequestLoaded) }
                .eraseToEffect()
            return [effect]
        }
    }
}
