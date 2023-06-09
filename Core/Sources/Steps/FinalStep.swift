import Foundation
import Combine

extension OwnID.CoreSDK.CoreViewModel {
    private struct Constants {
        static let contextKey = "context"
        static let payloadKey = "payload"
        static let loginIdKey = "loginId"
        static let errorKey = "error"
        static let dataKey = "data"
        static let metadataKey = "metadata"
        static let typeKey = "type"
        static let flowInfo = "flowInfo"
        static let authType = "authType"
    }
    
    struct FinalRequestBody: Encodable {
        let sessionVerifier: OwnID.CoreSDK.SessionVerifier
    }

    class FinalStep: BaseStep {
        override func run(state: inout OwnID.CoreSDK.CoreViewModel.State) -> [Effect<OwnID.CoreSDK.CoreViewModel.Action>] {
            let requestBody = FinalRequestBody(sessionVerifier: state.sessionVerifier)
            let requestLanguage = state.supportedLanguages.rawValue.first
            let action = state.session.perform(url: state.finalUrl,
                                               method: .post,
                                               body: requestBody)
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { response in
                    let context = response[Constants.contextKey] as? String ?? ""
                    OwnID.CoreSDK.logger.logCore(.entry(context: context, message: "Final Request Finished", Self.self))
                })
                .tryMap { response in
                    let context = response[Constants.contextKey] as? String ?? ""
                    guard let responsePayload = response[Constants.payloadKey] as? [String: Any] else { throw OwnID.CoreSDK.Error.requestResponseIsEmpty }
                    
                    if let serverError = responsePayload[Constants.errorKey] as? String {
                        let serverError = OwnID.CoreSDK.ServerError(error: serverError)
                        throw OwnID.CoreSDK.CoreErrorLogWrapper.coreLog(entry: .errorEntry(context: context, Self.self),
                                                                        error: .serverError(serverError: serverError))
                    }
                    let loginId = responsePayload[Constants.loginIdKey] as? String ?? ""
                    let data = responsePayload[Constants.dataKey]
                    let metadata = responsePayload[Constants.metadataKey]
                    let stringType = responsePayload[Constants.typeKey] as? String ?? ""
                    var authTypeValue: String?
                    if let flowInfo = response[Constants.flowInfo] as? [String: Any], let authType = flowInfo[Constants.authType] as? String {
                        authTypeValue = authType
                    }
                    let payload = OwnID.CoreSDK.Payload(dataContainer: data,
                                                        metadata: metadata,
                                                        context: context,
                                                        loginId: loginId,
                                                        responseType: OwnID.CoreSDK.StatusResponseType(rawValue: stringType) ?? .registrationInfo,
                                                        authType: authTypeValue,
                                                        requestLanguage: requestLanguage)
                    return payload
                }
                .mapError({ error in
                    if let error = error as? OwnID.CoreSDK.Error {
                        return error
                    }
                    return .requestResponseIsEmpty
                })
                .map { Action.statusRequestLoaded(response: $0) }
                .catch({ error in
                    return Just(Action.error(.coreLog(entry: .errorEntry(Self.self), error: error)))
                })
                .eraseToEffect()
            return [action]
        }
    }
}
