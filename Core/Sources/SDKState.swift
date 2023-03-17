import Foundation
import Combine

extension OwnID.CoreSDK {
    struct SDKState: LoggingEnabled {
        var isLoggingEnabled = false
        var configurations = [String: OwnID.CoreSDK.LocalConfiguration]()
        let configurationLoadingEventPublisher: PassthroughSubject<ConfigurationLoadingEvent, Never>
        var supportedLanguages: OwnID.CoreSDK.Languages = .init(rawValue: ["en"])
    }
}

extension OwnID.CoreSDK.SDKState {
    var firstConfiguration: OwnID.CoreSDK.LocalConfiguration? {
        guard let sdkConfigurationName = configurations.first?.key, let config = configurations[sdkConfigurationName] else { return .none }
        return config
    }
    
    func getOptionalConfiguration(for sdkConfigurationName: String) -> OwnID.CoreSDK.LocalConfiguration? {
        guard let config = configurations[sdkConfigurationName] else { return .none }
        return config
    }
    
    func getConfiguration(for sdkConfigurationName: String) -> OwnID.CoreSDK.LocalConfiguration {
        guard let config = configurations[sdkConfigurationName] else { fatalError("Configuration does not exist for name") }
        return config
    }
}
