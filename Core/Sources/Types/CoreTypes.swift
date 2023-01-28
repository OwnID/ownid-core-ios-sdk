import Foundation
import SwiftUI

public extension OwnID.CoreSDK {
    /// Describes translations to be used in SDK. Languages chosen by order of initialization.
    struct Languages: RawRepresentable {
        public init(rawValue: [String]) {
            self.rawValue = rawValue
        }
        
        /// Tells SDK to change language if system language changes
        var shouldChangeLanguageOnSystemLanguageChange = true
        
        public let rawValue: [String]
    }
}

public extension OwnID.CoreSDK {
    struct Fido2LoginPayload: Encodable {
        var credentialId: String
        var clientDataJSON: String
        var authenticatorData: String
        var signature: String
        let error: String? = nil
    }
    
    struct Fido2RegisterPayload: Encodable {
        var credentialId: String
        var clientDataJSON: String
        var attestationObject: String
    }
}

public extension OwnID.CoreSDK {
    enum RequestType: String, Codable {
        case register
        case login
    }
    
    enum StatusResponseType: String, CaseIterable {
        case registrationInfo
        case session
    }
}

public protocol StringToken {
    var rawValue: String { get }
}

public protocol RegisterParameters { }

public extension OwnID.CoreSDK {
    
    struct ServerError {
        public let error: String
    }
    
    struct JWTToken: Identifiable {
        public var id: String {
            jwtString
        }
        
        public let jwtString: String
        
        public init(for token: StringToken) {
            jwtString = Self.encoded(token: token.rawValue)
        }
        
        private init(plain: String) {
            jwtString = Self.encoded(token: plain)
        }
        
        private static func encoded(token: String) -> String {
            "{\"jwt\":\"\(token)\"}"
        }
        
        public static func initFromPlain(string: String) -> JWTToken {
            JWTToken(plain: string)
        }
    }
    
    struct Payload {
        /// Used for later processing and creating login\registration requests
        public let dataContainer: Any?
        public let metadata: Any?
        public let context: OwnID.CoreSDK.Context
        public let nonce: OwnID.CoreSDK.Nonce
        public let loginId: LoginID?
        public let responseType: StatusResponseType
        public let authType: AuthType?
        public let requestLanguage: String?
    }
    
    enum Event {
        case loading
        case success(Payload)
        case cancelled
    }
}

public extension OwnID.CoreSDK {
    struct Email: RawRepresentable {
        public init(rawValue: String) {
            rawInternalValue = rawValue
        }
        
        private let rawInternalValue: String
        
        public var rawValue: String {
            rawInternalValue.lowercased()
        }
        
        public var isValid: Bool {
            let trimmedText = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let dataDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return false }
            let range = NSMakeRange(0, NSString(string: trimmedText).length)
            let allMatches = dataDetector.matches(in: trimmedText,
                                                  options: [],
                                                  range: range)
            let emailRegEx = "(?:[a-z0-9!#${'$'}%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#${'$'}%&'*+/=?^_`{|}~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)])"
            let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            if allMatches.count == 1,
                allMatches.first?.url?.absoluteString.contains("mailto:") == true {
                return true && emailPredicate.evaluate(with: rawValue)
            }
            return false
        }
    }
}
