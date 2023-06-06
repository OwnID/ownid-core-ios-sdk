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
            
            return []
        }
        
        func sendAuthRequest(state: inout OwnID.CoreSDK.CoreViewModel.State,
                             loginId: String) -> [Effect<Action>] {
            guard let urlString = step.startingData?.url, let url = URL(string: urlString) else {
                return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .dataIsMissing))
            }

            let context = state.context
            let requestBody = IdCollectRequestBody(loginId: loginId, supportsFido2: OwnID.CoreSDK.isPasskeysSupported)
            state.loginId = loginId
            let effect = state.session.perform(url: url,
                                               method: .post,
                                               body: requestBody,
                                               with: StepResponse.self)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { response in
                    OwnID.CoreSDK.logger.logCore(.entry(context: context, message: "Auth Request Finished", Self.self))
                })
                .map { [self] in nextStepAction($0.step) }
                .catch { error in
                    let coreError: OwnID.CoreSDK.Error
                    switch error {
                    case OwnID.CoreSDK.ServiceError.networkFailed(let error):
                        coreError = .authRequestNetworkFailed(underlying: error)
                    case OwnID.CoreSDK.ServiceError.encodeFailed(let error):
                        coreError = .authRequestBodyEncodeFailed(underlying: error)
                    case OwnID.CoreSDK.ServiceError.decodeFailed(let error):
                        coreError = .authRequestResponseDecodeFailed(underlying: error)
                    case OwnID.CoreSDK.ServiceError.responseIsEmpty:
                        coreError = .authRequestResponseIsEmpty
                    }
                    return Just(Action.error(.coreLog(entry: .errorEntry(Self.self), error: coreError)))
                }
                .eraseToEffect()
            
            return [effect]
        }
    }
}
