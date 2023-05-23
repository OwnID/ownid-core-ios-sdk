import Foundation
import Combine

extension OwnID.CoreSDK.CoreViewModel {
    struct IdCollectRequestBody: Encodable {
        let loginId: String
    }
    
    struct IdCollectResponse: Decodable {
        let step: Step
    }
    
    class IdCollectStep: BaseStep {
        override func run(state: inout OwnID.CoreSDK.CoreViewModel.State) -> [Effect<OwnID.CoreSDK.CoreViewModel.Action>] {
            return []
        }
    }
}
