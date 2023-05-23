import Foundation
import Combine

extension OwnID.CoreSDK.CoreViewModel {
    struct FinalRequestBody: Encodable {
        let sessionVerifier: OwnID.CoreSDK.SessionVerifier
    }
    
    struct FinalResponse: Decodable {
        let context: String
        let status: String
        let flowInfo: FlowInfo
        
        let payload: PayloadResponse
    }
    
    struct FlowInfo: Decodable {
        let authType: String
        let event: String
    }
    
    struct PayloadResponse: Decodable {
        let data: OwnID.CoreSDK.PayloadData?
        let metadata: OwnID.CoreSDK.Metadata?
        let loginId: String?
        let type: String?
    }
    
    class FinalStep: BaseStep {
        override func run(state: inout OwnID.CoreSDK.CoreViewModel.State) -> [Effect<OwnID.CoreSDK.CoreViewModel.Action>] {
            let requestBody = FinalRequestBody(sessionVerifier: state.sessionVerifier)
            let requestLanguage = state.supportedLanguages.rawValue.first
            let action = state.session.perform(url: state.finalUrl,
                                               method: .post,
                                               body: requestBody,
                                               with: FinalResponse.self)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { response in
                    OwnID.CoreSDK.logger.logCore(.entry(context: response.context, message: "Final Request Finished", Self.self))
                })
                .map { response in
                    let payload = OwnID.CoreSDK.Payload(dataContainer: response.payload.data,
                                                        metadata: response.payload.metadata,
                                                        context: response.context,
                                                        loginId: response.payload.loginId,
                                                        responseType: OwnID.CoreSDK.StatusResponseType(rawValue: response.payload.type ?? "") ?? .registrationInfo,
                                                        authType: response.flowInfo.authType,
                                                        requestLanguage: requestLanguage)
                    return payload
                }
                .map { Action.statusRequestLoaded(response: $0) }
                .catch { error in
                    let coreError: OwnID.CoreSDK.Error
                    switch error {
                    case OwnID.CoreSDK.ServiceError.networkFailed(let error):
                        coreError = .statusRequestNetworkFailed(underlying: error)
                    case OwnID.CoreSDK.ServiceError.encodeFailed(let error):
                        coreError = .statusRequestBodyEncodeFailed(underlying: error)
                    case OwnID.CoreSDK.ServiceError.decodeFailed(let error):
                        coreError = .statusRequestResponseDecodeFailed(underlying: error)
                    case OwnID.CoreSDK.ServiceError.responseIsEmpty:
                        coreError = .statusRequestResponseIsEmpty
                    }
                    return Just(Action.error(.coreLog(entry: .errorEntry(Self.self), error: coreError)))
                }
                .eraseToEffect()
            return [action]
        }
    }
}
