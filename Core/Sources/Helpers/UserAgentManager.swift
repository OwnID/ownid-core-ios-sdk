import Foundation
import UIKit.UIDevice

public extension OwnID.CoreSDK {
    typealias SDKInformation = (name: String, verison: String)
    
    final class UserAgentManager {
        public static let shared = UserAgentManager()
        private init() { }
        
        private let modelName = UIDevice.modelName
        
        func registerUserFacingSDKName(_ userFacingSDK: SDKInformation, underlyingSDKs: [SDKInformation]) {
            mainSDKUserAgent = userAgent(for: userFacingSDK, underlyingSDKs: underlyingSDKs)
        }
        
        var userFacingSDKVersion: String {
            version
        }
        
        public lazy var mainSDKUserAgent = userAgent(for: (OwnID.CoreSDK.sdkName, OwnID.CoreSDK.version), underlyingSDKs: [])
        
        private func userAgent(for userFacingSDK: SDKInformation, underlyingSDKs: [SDKInformation]) -> String {
            let underlyingSDKsNames = underlyingSDKNames(underlyingSDKs: underlyingSDKs)
            let userFacingSDKName = sdkAgentName(sdkName: userFacingSDK.name, version: userFacingSDK.verison)
            return "\(userFacingSDKName) (iOS; iOS \(UIDevice.current.systemVersion); \(modelName)) \(underlyingSDKsNames) \(Bundle.main.bundleIdentifier!)"
        }
        
        private func sdkAgentName(sdkName: String, version: String) -> String {
            "OwnID-\(sdkName)/\(version)"
        }
        
        private func underlyingSDKNames(underlyingSDKs: [SDKInformation]) -> String {
            underlyingSDKs.reduce("") { partialResult, sdkInfo in
                partialResult + sdkAgentName(sdkName: sdkInfo.name, version: sdkInfo.verison)
            }
        }
    }
}
