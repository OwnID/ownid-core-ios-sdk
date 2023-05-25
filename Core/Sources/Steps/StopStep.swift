import Foundation
import Combine

extension OwnID.CoreSDK.CoreViewModel {
    struct EmptyBody: Codable { }
    
    class StopStep: BaseStep {
        override func run(state: inout State) -> [Effect<OwnID.CoreSDK.CoreViewModel.Action>] {
            let context = state.context
            let effect = state.session.perform(url: state.stopUrl,
                                               method: .post,
                                               body: EmptyBody(),
                                               with: EmptyBody.self)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { response in
                    OwnID.CoreSDK.logger.logCore(.entry(context: context, message: "Stop Request Finished", Self.self))
                })
                .map { _ in Action.stopRequestLoaded }
                .catch { _ in Just(Action.stopRequestLoaded) }
                .eraseToEffect()
            return [effect]
        }
    }
}
