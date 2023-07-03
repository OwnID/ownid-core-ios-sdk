import Foundation
import Combine
import CryptoKit

extension OwnID.CoreSDK.CoreViewModel {
    struct InitRequestBody: Encodable {
        let sessionChallenge: OwnID.CoreSDK.SessionChallenge
        let type: OwnID.CoreSDK.RequestType
        let loginId: String?
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
            
            let locales = OwnID.CoreSDK.TranslationsSDK.LanguageMapper.matchSystemLanguage(to: OwnID.CoreSDK.shared.supportedLocales ?? [],
                                                                                           userDefinedLanguages: state.supportedLanguages.rawValue)
            let session = OwnID.CoreSDK.SessionService(supportedLanguages: OwnID.CoreSDK.Languages(rawValue: [locales.serverLanguage]))
            state.session = session
            
            let sessionVerifierData = random()
            state.sessionVerifier = sessionVerifierData.toBase64URL()
            let sessionChallengeData = SHA256.hash(data: sessionVerifierData).data
            let sessionChallenge = sessionChallengeData.toBase64URL()

            OwnID.CoreSDK.logger.log(.entry(level: .information,
                                            message: "isFidoPossible \(OwnID.CoreSDK.isPasskeysSupported)",
                                            Self.self))
            let eventCategory: OwnID.CoreSDK.EventCategory = state.type == .login ? .login : .registration
            OwnID.CoreSDK.eventService.sendMetric(.trackMetric(action: .fidoSupports(isFidoSupported: OwnID.CoreSDK.isPasskeysSupported),
                                                               category: eventCategory,
                                                               loginId: state.loginId))
            
            let requestBody = InitRequestBody(sessionChallenge: sessionChallenge,
                                              type: state.type,
                                              loginId: state.loginId.isBlank ? nil : state.loginId,
                                              supportsFido2: OwnID.CoreSDK.isPasskeysSupported)
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
                OwnID.CoreSDK.logger.log(.entry(context: response.context, level: .debug, message: "Init Request Finished", Self.self))
            })
            .map { Action.initialRequestLoaded(response: $0) }
            .catch { Just(Action.error(.coreLog(entry: .errorEntry(Self.self), error: $0))) }
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
    }
}

extension Digest {
    var bytes: [UInt8] { Array(makeIterator()) }
    var data: Data { Data(bytes) }
}

extension Data {
    func toBase64URL() -> String {
        var encoded = base64EncodedString()
        encoded = encoded.replacingOccurrences(of: "+", with: "-")
        encoded = encoded.replacingOccurrences(of: "/", with: "_")
        encoded = encoded.replacingOccurrences(of: "=", with: "")
        return encoded
    }
}

