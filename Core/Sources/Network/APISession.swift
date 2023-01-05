import Foundation
import CryptoKit
import Combine

public protocol APISessionProtocol {
    var context: OwnID.CoreSDK.Context! { get }
    
    func performInitRequest(type: OwnID.CoreSDK.RequestType,
                            token: OwnID.CoreSDK.JWTToken?,
                            origin: String?) -> AnyPublisher<OwnID.CoreSDK.Init.Response, OwnID.CoreSDK.Error>
    func performStatusRequest(origin: String?) -> AnyPublisher<OwnID.CoreSDK.Payload, OwnID.CoreSDK.Error>
    func performSettingsRequest(loginID: String, origin: String) -> AnyPublisher<OwnID.CoreSDK.Setting.Response, OwnID.CoreSDK.Error>
    func performAuthRequest(origin: String, fido2Payload: Encodable) -> AnyPublisher<OwnID.CoreSDK.Payload, OwnID.CoreSDK.Error>
}

public extension OwnID.CoreSDK {
    final class APISession: APISessionProtocol {
        private let sessionVerifier: SessionVerifier
        private let sessionChallenge: SessionChallenge
        private var nonce: Nonce!
        public var context: Context!
        private var type: OwnID.CoreSDK.RequestType!
        private let serverURL: ServerURL
        private let statusURL: ServerURL
        private let settingsURL: ServerURL
        private let authURL: ServerURL
        private let webLanguages: OwnID.CoreSDK.Languages
        
        public init(serverURL: ServerURL,
                    statusURL: ServerURL,
                    settingsURL: ServerURL,
                    authURL: ServerURL,
                    webLanguages: OwnID.CoreSDK.Languages) {
            self.serverURL = serverURL
            self.statusURL = statusURL
            self.settingsURL = settingsURL
            self.authURL = authURL
            self.webLanguages = webLanguages
            let sessionVerifierData = Self.random()
            sessionVerifier = sessionVerifierData.toBase64URL()
            let sessionChallengeData = SHA256.hash(data: sessionVerifierData).data
            sessionChallenge = sessionChallengeData.toBase64URL()
        }
    }
}

extension OwnID.CoreSDK.APISession {
    public func performInitRequest(type: OwnID.CoreSDK.RequestType,
                                   token: OwnID.CoreSDK.JWTToken?,
                                   origin: String?) -> AnyPublisher<OwnID.CoreSDK.Init.Response, OwnID.CoreSDK.Error> {
        OwnID.CoreSDK.Init.Request(type: type,
                                   url: serverURL,
                                   sessionChallenge: sessionChallenge,
                                   token: token,
                                   origin: origin,
                                   webLanguages: webLanguages)
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
    
    public func performSettingsRequest(loginID: String, origin: String) -> AnyPublisher<OwnID.CoreSDK.Setting.Response, OwnID.CoreSDK.Error> {
        OwnID.CoreSDK.Setting.Request(url: settingsURL,
                                      loginID: loginID,
                                      origin: origin,
                                      context: context,
                                      nonce: nonce,
                                      webLanguages: webLanguages)
        .perform()
        .eraseToAnyPublisher()
    }
    
    public func performAuthRequest(origin: String, fido2Payload: Encodable) -> AnyPublisher<OwnID.CoreSDK.Payload, OwnID.CoreSDK.Error> {
        OwnID.CoreSDK.Auth.Request(type: type,
                                   url: authURL,
                                   context: context,
                                   nonce: nonce,
                                   origin: origin,
                                   sessionVerifier: sessionVerifier,
                                   fido2LoginPayload: fido2Payload,
                                   webLanguages: webLanguages)
        .perform()
        .eraseToAnyPublisher()
    }
    
    public func performStatusRequest(origin: String?) -> AnyPublisher<OwnID.CoreSDK.Payload, OwnID.CoreSDK.Error> {
        OwnID.CoreSDK.Status.Request(url: statusURL,
                                     context: context,
                                     nonce: nonce,
                                     sessionVerifier: sessionVerifier,
                                     type: type,
                                     origin: origin,
                                     webLanguages: webLanguages)
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
