import Foundation
import Combine
import LocalAuthentication
import CryptoKit

extension OwnID.CoreSDK.CoreViewModel {
    struct InitRequestBody: Encodable {
        let sessionChallenge: OwnID.CoreSDK.SessionChallenge
        let type: OwnID.CoreSDK.RequestType
        let loginId: String
        let supportsFido2: Bool
        var qr = false
        var passkeyAutofill = false
    }
    
    struct InitResponse: Decodable {
        var context: String
        let expiration: Int?
        let stopUrl: String
        let finalStatusUrl: String
        
        let step: Step
    }
    
    class InitStep: BaseStep {
        override func run(state: inout State) -> [Effect<Action>] {
            guard let configuration = state.configuration else {
                return errorEffect(.coreLog(entry: .errorEntry(Self.self), error: .localConfigIsNotPresent))
            }
            
            let session = OwnID.CoreSDK.SessionService(supportedLanguages: state.supportedLanguages)
            state.session = session
            
            let sessionVerifierData = random()
            state.sessionVerifier = sessionVerifierData.toBase64URL()
            let sessionChallengeData = SHA256.hash(data: sessionVerifierData).data
            let sessionChallenge = sessionChallengeData.toBase64URL()

            let requestBody = InitRequestBody(sessionChallenge: sessionChallenge,
                                              type: state.type,
                                              loginId: state.loginId,
                                              supportsFido2: isPasskeysSupported)
            return [sendInitialRequest(requestBody: requestBody, session: session, configuration: configuration)]
        }
        
        private func sendInitialRequest(requestBody: InitRequestBody,
                                        session: OwnID.CoreSDK.SessionService,
                                        configuration: OwnID.CoreSDK.LocalConfiguration) -> Effect<Action> {
            session.perform(url: configuration.initURL,
                            method: .post,
                            body: requestBody,
                            with: InitResponse.self)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { response in
                OwnID.CoreSDK.logger.logCore(.entry(context: response.context, message: "Init Request Finished", Self.self))
            })
            .map { Action.initialRequestLoaded(response: $0) }
            .catch { error in
                let coreError: OwnID.CoreSDK.Error
                switch error {
                case OwnID.CoreSDK.ServiceError.networkFailed(let error):
                    coreError = .initRequestNetworkFailed(underlying: error)
                case OwnID.CoreSDK.ServiceError.encodeFailed(let error):
                    coreError = .initRequestBodyEncodeFailed(underlying: error)
                case OwnID.CoreSDK.ServiceError.decodeFailed(let error):
                    coreError = .initRequestResponseDecodeFailed(underlying: error)
                case OwnID.CoreSDK.ServiceError.responseIsEmpty:
                    coreError = .initRequestResponseIsEmpty
                }
                return Just(Action.error(.coreLog(entry: .errorEntry(Self.self), error: coreError)))
            }
            .eraseToEffect()
        }
        
        private func random(_ bytes: Int = 32) -> Data {
            var keyData = Data(count: bytes)
            let resultStatus = keyData.withUnsafeMutableBytes {
                SecRandomCopyBytes(kSecRandomDefault, bytes, $0.baseAddress!)
            }
            if resultStatus != errSecSuccess {
                fatalError()
            }
            return keyData
        }
        
        private var isPasskeysSupported: Bool {
            let isLeastPasskeysSupportediOS = ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 16, minorVersion: 0, patchVersion: 0))
            var isBiometricsAvailable = false
            let authContext = LAContext()
            let _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            switch authContext.biometryType {
            case .none:
                break
            case .touchID:
                isBiometricsAvailable = true
            case .faceID:
                isBiometricsAvailable = true
            @unknown default:
                print("please update biometrics types")
            }
            let isPasscodeAvailable = LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
            let isPasskeysSupported = isLeastPasskeysSupportediOS && (isBiometricsAvailable || isPasscodeAvailable)
            return isPasskeysSupported
        }
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

