import Foundation
import UIKit.UIDevice

public extension OwnID.CoreSDK {
    /// Relates version and name of the client.
    /// Examples:
    /// name - "com.example.myapp", "DemoApplication"
    /// version - "0.0.5", "3.34.7"
    typealias SDKInformation = (name: String, verison: String)
    
    final class UserAgentManager {
        public static let shared = UserAgentManager()
        private init() { }
        
        private let modelName = UIDevice.modelName
        
        func registerUserFacingSDKName(_ userFacingSDK: SDKInformation, underlyingSDKs: [SDKInformation]) {
            var allUnderlyingSDKs: [SDKInformation] = [(OwnID.CoreSDK.sdkName, OwnID.CoreSDK.version)]
            allUnderlyingSDKs.append(contentsOf: underlyingSDKs)
            self.underlyingSDKs = allUnderlyingSDKs.map { $0.name }
            SDKUserAgent = userAgent(for: userFacingSDK, underlyingSDKs: allUnderlyingSDKs)
        }
        
        var userFacingSDKVersion: String { version }
        var systemVersion: String { UIDevice.current.systemVersion }
        
        public lazy var underlyingSDKs = [OwnID.CoreSDK.sdkName]
        public lazy var SDKUserAgent = userAgent(for: (OwnID.CoreSDK.sdkName, OwnID.CoreSDK.version), underlyingSDKs: [])
        
        private func userAgent(for userFacingSDK: SDKInformation, underlyingSDKs: [SDKInformation]) -> String {
            let underlyingSDKsNames = underlyingSDKNames(underlyingSDKs: underlyingSDKs)
            let userFacingSDKName = sdkAgentName(sdkName: userFacingSDK.name, version: userFacingSDK.verison)
            return "\(userFacingSDKName) (iOS; iOS \(systemVersion); \(modelName)) \(underlyingSDKsNames) \(Bundle.main.bundleIdentifier!)"
        }
        
        private func sdkAgentName(sdkName: String, version: String) -> String {
            "OwnID-\(sdkName)/\(version)"
        }
        
        private func underlyingSDKNames(underlyingSDKs: [SDKInformation]) -> String {
            underlyingSDKs.reduce("") { partialResult, sdkInfo in
                let newUnderlying = sdkAgentName(sdkName: sdkInfo.name, version: sdkInfo.verison)
                if partialResult == "" {
                    return newUnderlying
                } else {
                    return partialResult +  " " + newUnderlying
                }
            }
        }
    }
}
