import Foundation
import Combine

extension OwnID.CoreSDK.CoreViewModel {
    struct OTPAuthRequestBody: Encodable {
        let code: String
    }
    
    struct OTPAuthResponse: Decodable {
        
    }
    
    class OTPAuthStep: BaseStep {
        private let step: Step
        
        init(step: Step) {
            self.step = step
        }
        
        override func run(state: inout OwnID.CoreSDK.CoreViewModel.State) -> [Effect<OwnID.CoreSDK.CoreViewModel.Action>] {
            return []
        }
    }
}
