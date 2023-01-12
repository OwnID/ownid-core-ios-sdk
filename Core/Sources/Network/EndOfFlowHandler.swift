import Combine

extension OwnID.CoreSDK {
    
    final class EndOfFlowHandler {
#warning("not status request here, others possible too")
        static func handle(inputPublisher: AnyPublisher<URLRequest, OwnID.CoreSDK.CoreErrorLogWrapper>,
                           context: OwnID.CoreSDK.Context,
                           nonce: OwnID.CoreSDK.Nonce,
                           requestLanguage: String?,
                           provider: APIProvider,
                           shouldIgnoreResponseBody: Bool) -> AnyPublisher<OwnID.CoreSDK.Payload, OwnID.CoreSDK.CoreErrorLogWrapper> {
            inputPublisher
                .flatMap { request -> AnyPublisher<URLSession.DataTaskPublisher.Output, OwnID.CoreSDK.CoreErrorLogWrapper> in provider.apiResponse(for: request)
                        .mapError { OwnID.CoreSDK.CoreErrorLogWrapper.coreLog(entry: .errorEntry(context: context, Self.self), error: .statusRequestNetworkFailed(underlying: $0)) }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
                .tryMap { response -> [String: Any] in
                    guard !response.data.isEmpty else { throw OwnID.CoreSDK.Error.statusRequestResponseIsEmpty }
                    guard let json = try JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any] else {
                        throw OwnID.CoreSDK.CoreErrorLogWrapper.coreLog(entry: .errorEntry(context: context, Self.self), error: .statusRequestResponseIsEmpty)
                    }
                    return json
                }
                .eraseToAnyPublisher()
                .tryMap { response -> OwnID.CoreSDK.Payload in
                    if shouldIgnoreResponseBody {
                        return OwnID.CoreSDK.Payload(dataContainer: .none, metadata: .none, context: context, nonce: nonce, loginId: .none, responseType: .registrationInfo, authType: .none, requestLanguage: .none)
                    }
                    guard let responseContext = response["context"] as? String else { throw OwnID.CoreSDK.Error.statusRequestResponseIsEmpty }
                    guard context == responseContext else { throw OwnID.CoreSDK.Error.statusRequestResponseContextMismatch }
                    guard let responsePayload = response["payload"] as? [String: Any] else { throw OwnID.CoreSDK.Error.statusRequestResponseIsEmpty }
                    
                    if let serverError = responsePayload["error"] as? String {
                        let serverError = OwnID.CoreSDK.ServerError(error: serverError)
                        throw OwnID.CoreSDK.CoreErrorLogWrapper.coreLog(entry: .errorEntry(context: responseContext, Self.self), error: .serverError(serverError: serverError))
                    }
                    
                    let responseData = responsePayload["data"]
                    
                    let loginId = responsePayload["loginId"] as? OwnID.CoreSDK.LoginID
                    
                    let metadataDict = responsePayload["metadata"] as? [String: Any]
                    
                    guard let stringType = responsePayload["type"] as? OwnID.CoreSDK.LoginID,
                          let requestResponseType = OwnID.CoreSDK.StatusResponseType(rawValue: stringType) else { throw OwnID.CoreSDK.Error.statusRequestTypeIsMissing }
                    var authTypeValue: String?
                    if let flowInfo = response["flowInfo"] as? [String: Any], let authType = flowInfo["authType"] as? String {
                        authTypeValue = authType
                    }
                    let payload = OwnID.CoreSDK.Payload(dataContainer: responseData,
                                                        metadata: metadataDict,
                                                        context: context,
                                                        nonce: nonce,
                                                        loginId: loginId,
                                                        responseType: requestResponseType,
                                                        authType: authTypeValue,
                                                        requestLanguage: requestLanguage)
                    
                    OwnID.CoreSDK.logger.logCore(.entry(context: context, message: "Finished request", Self.self))
                    return payload
                }
                .eraseToAnyPublisher()
                .mapError { initError in
                    guard let error = initError as? OwnID.CoreSDK.Error else { return  .coreLog(entry: .errorEntry(context: context, Self.self), error: .statusRequestFail(underlying: initError)) }
                    return .coreLog(entry: .errorEntry(context: context, Self.self), error: error)
                }
                .eraseToAnyPublisher()
        }
    }
}
