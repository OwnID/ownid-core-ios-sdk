import Foundation
import CryptoKit
import Combine

public protocol APISessionProtocol {
    var context: OwnID.CoreSDK.Context! { get }
    
    func performInitRequest(requestData: OwnID.CoreSDK.Init.RequestData) -> AnyPublisher<OwnID.CoreSDK.Init.Response, OwnID.CoreSDK.CoreErrorLogWrapper>
    func performFinalStatusRequest() -> AnyPublisher<OwnID.CoreSDK.Payload, OwnID.CoreSDK.CoreErrorLogWrapper>
    func performAuthRequest(fido2Payload: Encodable) -> AnyPublisher<OwnID.CoreSDK.Payload, OwnID.CoreSDK.CoreErrorLogWrapper>
}

public extension OwnID.CoreSDK {
    final class APISession: APISessionProtocol {
        private let sessionVerifier: SessionVerifier
        private let sessionChallenge: SessionChallenge
        private var nonce: Nonce!
        public var context: Context!
        private var type: OwnID.CoreSDK.RequestType!
        private let initURL: ServerURL
        private let statusURL: ServerURL
        private let finalStatusURL: ServerURL
        private let authURL: ServerURL
        private let supportedLanguages: OwnID.CoreSDK.Languages
        
        public init(initURL: ServerURL,
                    statusURL: ServerURL,
                    finalStatusURL: ServerURL,
                    authURL: ServerURL,
                    supportedLanguages: OwnID.CoreSDK.Languages) {
            self.initURL = initURL
            self.statusURL = statusURL
            self.finalStatusURL = finalStatusURL
            self.authURL = authURL
            self.supportedLanguages = supportedLanguages
            let sessionVerifierData = Self.random()
            sessionVerifier = sessionVerifierData.toBase64URL()
            let sessionChallengeData = SHA256.hash(data: sessionVerifierData).data
            sessionChallenge = sessionChallengeData.toBase64URL()
        }
    }
}

extension OwnID.CoreSDK.APISession {
    public func performInitRequest(requestData: OwnID.CoreSDK.Init.RequestData) -> AnyPublisher<OwnID.CoreSDK.Init.Response, OwnID.CoreSDK.CoreErrorLogWrapper> {
        OwnID.CoreSDK.Init.Request(requestData: requestData,
                                   url: initURL,
                                   sessionChallenge: sessionChallenge,
                                   supportedLanguages: supportedLanguages)
        .perform()
        .map { [unowned self] response in
            nonce = response.nonce
            context = response.context
            self.type = type
            OwnID.CoreSDK.logger.logCore(.entry(context: context, message: "\(OwnID.CoreSDK.Init.Request.self): Finished", Self.self))
            return response
        }
        .eraseToAnyPublisher()
    }
    
    public func performAuthRequest(fido2Payload: Encodable) -> AnyPublisher<OwnID.CoreSDK.Payload, OwnID.CoreSDK.CoreErrorLogWrapper> {
        OwnID.CoreSDK.Auth.Request(type: type,
                                   url: authURL,
                                   context: context,
                                   nonce: nonce,
                                   sessionVerifier: sessionVerifier,
                                   fido2LoginPayload: fido2Payload,
                                   supportedLanguages: supportedLanguages)
        .perform()
        .eraseToAnyPublisher()
    }
    
    public func performFinalStatusRequest() -> AnyPublisher<OwnID.CoreSDK.Payload, OwnID.CoreSDK.CoreErrorLogWrapper> {
        OwnID.CoreSDK.Status.Request(url: finalStatusURL,
                                     context: context,
                                     nonce: nonce,
                                     sessionVerifier: sessionVerifier,
                                     type: type,
                                     supportedLanguages: supportedLanguages)
        .perform()
        .handleEvents(receiveOutput: { payload in
            OwnID.CoreSDK.logger.logCore(.entry(context: payload.context, message: "\(OwnID.CoreSDK.Status.Request.self): Finished", Self.self))
        })
        .eraseToAnyPublisher()
    }
}

private extension OwnID.CoreSDK.APISession {
    static func random(_ bytes: Int = 32) -> Data {
        var keyData = Data(count: bytes)
        let resultStatus = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, bytes, $0.baseAddress!)
        }
        if resultStatus != errSecSuccess {
            fatalError()
        }
        return keyData
    }
}

private extension Digest {
    var bytes: [UInt8] { Array(makeIterator()) }
    var data: Data { Data(bytes) }
}

private extension Data {
    func toBase64URL() -> String {
        var encoded = base64EncodedString()
        encoded = encoded.replacingOccurrences(of: "+", with: "-")
        encoded = encoded.replacingOccurrences(of: "/", with: "_")
        encoded = encoded.replacingOccurrences(of: "=", with: "")
        return encoded
    }
}
