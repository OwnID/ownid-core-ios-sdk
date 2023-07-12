import Foundation

extension OwnID.CoreSDK.CoreViewModel {
    struct Step: Decodable {
        enum StepType: String, Decodable {
            case starting
            case fido2Authorize
            case linkWithCode
            case loginIDAuthorization
            case verifyLoginID
            case showQr
            case success
        }
        
        let type: StepType
        private(set) var startingData: StartingStepData?
        private(set) var fidoData: FidoStepData?
        private(set) var otpData: OTPStepData?
        private(set) var webAppData: WebAppStepData?
        
        enum CodingKeys: CodingKey {
            case type
            case data
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.type = try container.decode(StepType.self, forKey: .type)
            
            switch type {
            case .starting:
                self.startingData = try container.decodeIfPresent(StartingStepData.self, forKey: .data)
            case .fido2Authorize:
                self.fidoData = try container.decodeIfPresent(FidoStepData.self, forKey: .data)
            case .linkWithCode, .loginIDAuthorization, .verifyLoginID:
                self.otpData = try container.decodeIfPresent(OTPStepData.self, forKey: .data)
            case .showQr:
                self.webAppData = try container.decodeIfPresent(WebAppStepData.self, forKey: .data)
            case .success:
                break
            }
        }
    }
    
    struct StartingStepData: Decodable {
        let url: String
    }
    
    struct FidoStepData: Decodable {
        let relyingPartyId: String
        let relyingPartyName: String
        let url: String
        let userDisplayName: String
        let userName: String
        let credId: String?
    }
    
    struct OTPStepData: Decodable {
        let url: String
        let restartUrl: String
        let resendUrl: String
        let verificationType: OwnID.CoreSDK.Verification.VerificationType
        let otpLength: Int?
    }
    
    struct WebAppStepData: Decodable {
        let url: String
    }
    
    struct ErrorData: Decodable {
        let errorCode: String?
        let message: String?
        let userMessage: String?
        let flowFinished: Bool?
        
        init(errorCode: String?, message: String?, userMessage: String?, flowFinished: Bool?) {
            self.errorCode = errorCode
            self.message = message
            self.userMessage = userMessage
            self.flowFinished = flowFinished
        }
    }
}
